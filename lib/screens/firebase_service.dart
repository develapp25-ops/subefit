import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:subefit/screens/post_model.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/screens/comment_model.dart';
import 'package:subefit/screens/challenge_model.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene el perfil de un usuario desde la colección 'Usuarios'.
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('Usuarios').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error al obtener perfil de usuario: $e');
    }
    return null;
  }

  /// Actualiza los datos del perfil de un usuario.
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    // Usamos .set con merge:true en lugar de .update().
    // Esto es más robusto: crea el documento si no existe o lo actualiza si ya existe.
    // Soluciona el error de permisos que ocurre si se intenta actualizar antes de que el documento se haya creado.
    await _db
        .collection('Usuarios')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// Inicializa el perfil de un nuevo usuario en Firestore.
  Future<void> initializeUserProfile(
      {required String userId,
      required String email,
      String? displayName}) async {
    final userRef = _db.collection('Usuarios').doc(userId);
    final doc = await userRef.get();

    // Solo crear el documento si no existe
    if (!doc.exists) {
      await userRef.set({
        'email': email,
        'nombre': displayName,
        'nombre_lowercase': displayName?.toLowerCase() ?? 'atleta anónimo',
        'biografia': '',
        'publico': true,
        'seguidores': 0,
        'seguidos': 0,
        'publicaciones': 0,
        'weight': 0.0,
        'height': 0.0,
        'goals': '',
        'isProfileComplete': false,
        'level': 1,
        'totalPoints': 0,
        'streak': 0,
        'settings': {
          'language': 'es',
          'voiceGender': 'Femenino',
        }
      });
    }
  }

  /// Comprueba si un nombre de usuario ya existe en la colección 'Usuarios'.
  /// La búsqueda no distingue entre mayúsculas y minúsculas.
  Future<bool> checkUsernameExists(String username) async {
    try {
      final snapshot = await _db
          .collection('Usuarios')
          .where('nombre_lowercase', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al comprobar el nombre de usuario: $e');
      return false; // Asumir que no existe en caso de error para no bloquear el registro.
    }
  }

  /// Obtiene el perfil de un usuario por su nombre de usuario.
  Future<UserProfile?> getUserProfileByUsername(String username) async {
    try {
      final snapshot = await _db
          .collection('Usuarios')
          .where('nombre_lowercase', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return UserProfile.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      debugPrint('Error al obtener perfil por nombre de usuario: $e');
    }
    return null;
  }

  /// Obtiene las publicaciones para el feed principal.
  /// Solo trae las que son públicas y las ordena por fecha.
  /// Si se provee [currentUserId], traerá las publicaciones de los usuarios que sigue.
  Future<List<Post>> getFeedPosts(
      {String? currentUserId, int limit = 20}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;

      if (currentUserId != null) {
        // 1. Obtener la lista de IDs de usuarios seguidos
        final followingSnapshot = await _db
            .collection('Seguidos')
            .doc(currentUserId)
            .collection('userFollowing')
            .get();
        final followingIds =
            followingSnapshot.docs.map((doc) => doc.id).toList();

        // Si el usuario sigue a alguien, mostramos el feed de esas personas.
        if (followingIds.isNotEmpty) {
          snapshot = await _db
              .collection('Publicacion')
              .where('autorID', whereIn: followingIds)
              .orderBy('fecha', descending: true)
              .limit(limit)
              .get();
        } else {
          // Si no sigue a nadie, mostramos posts públicos generales para que el feed no esté vacío.
          snapshot = await _db
              .collection('Publicacion')
              .where('publico', isEqualTo: true)
              .orderBy('fecha', descending: true)
              .limit(limit)
              .get();
        }
      } else {
        // Comportamiento para usuarios no logueados: mostrar posts públicos de todos
        snapshot = await _db
            .collection('Publicacion')
            .where('publico', isEqualTo: true)
            .orderBy('fecha', descending: true)
            .limit(limit)
            .get();
      }

      if (snapshot.docs.isEmpty) return [];

      // Obtenemos todos los autores para no hacer una consulta por cada post
      final authorIds = snapshot.docs
          .map((doc) => doc.data()['autorID'] as String)
          .toSet()
          .toList();
      final authorProfiles = await _getAuthorProfiles(authorIds);

      // Filtramos los posts para asegurarnos de que el autor todavía existe.
      // Esto previene que se muestren posts de usuarios eliminados.
      final validPosts = snapshot.docs.where((doc) {
        final authorId = doc.data()['autorID'];
        return authorProfiles.containsKey(authorId);
      }).map((doc) {
        final postData = Map<String, dynamic>.from(doc.data());
        final author = authorProfiles[postData['autorID']];
        return Post.fromFirestore(doc, author);
      }).toList();

      return validPosts;
    } catch (e) {
      debugPrint('Error al obtener posts del feed: $e');
      return [];
    }
  }

  /// Obtiene las publicaciones de un usuario específico.
  Future<List<Post>> getUserPosts(String userId,
      {String? currentUserId}) async {
    try {
      final isOwnProfile = userId == currentUserId;
      // NOTA DE ÍNDICE: Para que esta consulta funcione, se necesita un índice compuesto en Firestore
      // para la colección `Publicacion`.
      //
      // Campos del índice (crear desde el enlace del error o manualmente):
      // 1. `autorID` (Ascendente)
      // 2. `publico` (Ascendente)
      // 3. `fecha` (Descendente)

      Query<Map<String, dynamic>> query =
          _db.collection('Publicacion').where('autorID', isEqualTo: userId);

      // Si no estamos viendo nuestro propio perfil, solo mostramos las publicaciones públicas.
      if (!isOwnProfile) {
        query = query.where('publico', isEqualTo: true);
      }

      final snapshot = await query.orderBy('fecha', descending: true).get();

      // Obtenemos el perfil del autor para pasarlo al modelo del Post.
      final authorProfile = await getUserProfile(userId);

      // Si el perfil del autor no existe (p. ej., fue eliminado), no devolvemos ninguna publicación.
      if (authorProfile == null) return [];

      // Mapeamos los documentos a objetos Post, usando el perfil del autor ya obtenido.
      return snapshot.docs
          .map((doc) => Post.fromFirestore(doc, authorProfile))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener posts del usuario: $e');
      return [];
    }
  }

  /// Obtiene una lista de perfiles de usuarios públicos para la búsqueda.
  Future<List<UserProfile>> searchPublicUsers(
      {String query = '', int limit = 20}) async {
    try {
      Query queryBuilder = _db
          .collection('Usuarios')
          .where('publico', isEqualTo: true)
          .limit(limit);

      // Búsqueda simple por nombre (requiere índice en Firestore)
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder
            .where('nombre_lowercase',
                isGreaterThanOrEqualTo: query.toLowerCase())
            .where('nombre_lowercase',
                isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff');
      }

      final snapshot = await queryBuilder.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al buscar usuarios: $e');
      return [];
    }
  }

  /// Obtiene una lista de usuarios sugeridos para seguir.
  /// Excluye al usuario actual y a los que ya sigue.
  Future<List<UserProfile>> getSuggestedUsers(String currentUserId,
      {int limit = 10}) async {
    try {
      // 1. Obtener la lista de IDs de usuarios que el usuario actual ya sigue.
      final followingSnapshot = await _db
          .collection('Seguidos')
          .doc(currentUserId)
          .collection('userFollowing')
          .get();
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();

      // 2. Añadir el ID del propio usuario a la lista de exclusión.
      final excludedIds = [...followingIds, currentUserId];

      // 3. Obtener usuarios que no estén en la lista de exclusión.
      // NOTA: Firestore no soporta consultas 'not-in' con más de 10 elementos directamente de forma eficiente
      // para grandes datasets. Una mejor aproximación a gran escala sería usar una Cloud Function
      // para generar listas de sugerencias. Para una app de tamaño pequeño a mediano, esta consulta es aceptable.

      // La cláusula 'whereNotIn' no puede recibir una lista vacía.
      // Aunque 'excludedIds' siempre contendrá al menos al usuario actual,
      // esta comprobación hace la función más robusta.
      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (excludedIds.isNotEmpty) {
        snapshot = await _db
            .collection('Usuarios')
            .where(FieldPath.documentId, whereNotIn: excludedIds)
            .orderBy('totalPoints',
                descending:
                    true) // Ordenamos por puntos para sugerir usuarios más activos.
            .limit(limit)
            .get();
      } else {
        // Caso improbable, pero si no hay IDs que excluir, simplemente obtenemos algunos usuarios.
        snapshot = await _db
            .collection('Usuarios')
            .orderBy('totalPoints', descending: true)
            .limit(limit)
            .get();
      }
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener usuarios sugeridos: $e');
      return [];
    }
  }

  /// Obtiene las publicaciones para el feed de "Descubrir".
  /// Trae posts públicos de usuarios que el usuario actual no sigue.
  Future<List<Post>> getDiscoverPosts(
      {String? currentUserId, int limit = 20}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('Publicacion')
          .where('publico', isEqualTo: true)
          .orderBy('fecha', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) return [];

      // Obtenemos todos los autores para no hacer una consulta por cada post
      final authorIds = snapshot.docs
          .map((doc) => doc.data()['autorID'] as String)
          .toSet()
          .toList();
      final authorProfiles = await _getAuthorProfiles(authorIds);

      final validPosts = snapshot.docs.where((doc) {
        final authorId = doc.data()['autorID'];
        return authorProfiles.containsKey(authorId);
      }).map((doc) {
        return Post.fromFirestore(doc, authorProfiles[doc.data()['autorID']]);
      }).toList();

      return validPosts;
    } catch (e) {
      debugPrint('Error al obtener posts de descubrimiento: $e');
      return [];
    }
  }

  /// Comprueba si el usuario actual sigue a otro usuario.
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await _db
          .collection('Seguidos')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error al comprobar si sigue: $e');
      return false;
    }
  }

  /// Obtiene la lista de perfiles de usuario a los que un usuario sigue.
  Future<List<UserProfile>> getFollowingUsers(String currentUserId,
      {int limit = 20}) async {
    try {
      // 1. Obtener la lista de IDs de usuarios seguidos
      final followingSnapshot = await _db
          .collection('Seguidos')
          .doc(currentUserId)
          .collection('userFollowing')
          .limit(limit)
          .get();

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();

      if (followingIds.isEmpty) return [];

      // 2. Obtener los perfiles completos de esos usuarios
      final profilesMap = await _getAuthorProfiles(followingIds);
      return profilesMap.values.toList();
    } catch (e) {
      debugPrint('Error al obtener usuarios seguidos: $e');
      return [];
    }
  }

  /// Comprueba si el usuario actual ha enviado una solicitud de seguimiento a otro usuario.
  Future<bool> hasSentFollowRequest(
      String currentUserId, String targetUserId) async {
    try {
      final doc = await _db
          .collection('SolicitudesSeguimiento')
          .doc(targetUserId)
          .collection('pendingRequests')
          .doc(currentUserId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error al comprobar solicitud de seguimiento: $e');
      return false;
    }
  }

  /// Lógica para seguir, dejar de seguir, o enviar/cancelar una solicitud de seguimiento.
  ///
  /// - Si `isCurrentlyFollowing` es true, siempre se dejará de seguir.
  /// - Si es false, se comprobará si el perfil del `targetUserId` es público o privado.
  ///   - Si es público, se sigue directamente.
  ///   - Si es privado, se envía una solicitud de seguimiento.
  /// - Si ya se ha enviado una solicitud, se cancelará.
  Future<void> toggleFollow(String currentUserId, String targetUserId,
      bool isCurrentlyFollowing) async {
    final currentUserRef = _db.collection('Usuarios').doc(currentUserId);
    final targetUserRef = _db.collection('Usuarios').doc(targetUserId);

    final followingRef = _db
        .collection('Seguidos')
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(targetUserId);
    final followersRef = _db
        .collection('Seguidores')
        .doc(targetUserId)
        .collection('userFollowers')
        .doc(currentUserId);

    // Si ya se está siguiendo, la única acción posible es dejar de seguir.
    if (isCurrentlyFollowing) {
      await _db.runTransaction((transaction) async {
        transaction.delete(followingRef);
        transaction.delete(followersRef);
        transaction.set(currentUserRef, {'seguidos': FieldValue.increment(-1)},
            SetOptions(merge: true));
        transaction.set(targetUserRef, {'seguidores': FieldValue.increment(-1)},
            SetOptions(merge: true));
      });
      return;
    }

    // Si no se está siguiendo, comprobamos el estado del perfil del usuario objetivo.
    final targetProfile = await getUserProfile(targetUserId);
    if (targetProfile == null) {
      throw Exception('El perfil del usuario no existe.');
    }

    if (targetProfile.publico) {
      // --- Seguir a un perfil PÚBLICO ---
      await _db.runTransaction((transaction) async {
        transaction
            .set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction
            .set(followersRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.set(currentUserRef, {'seguidos': FieldValue.increment(1)},
            SetOptions(merge: true));
        transaction.set(targetUserRef, {'seguidores': FieldValue.increment(1)},
            SetOptions(merge: true));
      });
    } else {
      // --- Gestionar solicitud para un perfil PRIVADO ---
      final requestRef = _db
          .collection('SolicitudesSeguimiento')
          .doc(targetUserId)
          .collection('pendingRequests')
          .doc(currentUserId);
      final requestDoc = await requestRef.get();

      if (requestDoc.exists) {
        // Si la solicitud ya existe, la cancelamos.
        await requestRef.delete();
      } else {
        // Si no existe, la creamos.
        await requestRef.set({'timestamp': FieldValue.serverTimestamp()});
      }
    }
  }

  /// Acepta una solicitud de seguimiento.
  /// `currentUserId` es el usuario que acepta, `requesterId` es quien envió la solicitud.
  Future<void> acceptFollowRequest(
      String currentUserId, String requesterId) async {
    // Esta función ejecutaría una transacción similar a `toggleFollow` para crear la relación
    // y además borraría la solicitud de la colección `SolicitudesSeguimiento`.
    // Por ahora, la dejamos preparada para cuando construyas la UI de notificaciones.
    debugPrint(
        'Función acceptFollowRequest llamada. Implementar transacción aquí.');
  }

  /// Rechaza una solicitud de seguimiento.
  Future<void> rejectFollowRequest(
      String currentUserId, String requesterId) async {
    final requestRef = _db
        .collection('SolicitudesSeguimiento')
        .doc(currentUserId)
        .collection('pendingRequests')
        .doc(requesterId);
    await requestRef.delete();
    debugPrint('Solicitud de $requesterId a $currentUserId rechazada.');
  }

  /// Comprueba si un usuario ha dado like a una publicación.
  Future<bool> hasLikedPost(String userId, String postId) async {
    try {
      final likeDoc = await _db
          .collection('Publicacion')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error al comprobar like: $e');
      return false;
    }
  }

  /// Lógica para dar o quitar like a una publicación.
  Future<void> toggleLike(String userId, String postId, bool hasLiked) async {
    final postRef = _db.collection('Publicacion').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    return _db.runTransaction((transaction) async {
      if (hasLiked) {
        // --- Quitar Like ---
        transaction.delete(likeRef);
        transaction.set(postRef, {'likes': FieldValue.increment(-1)},
            SetOptions(merge: true));
      } else {
        // --- Dar Like ---
        transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
        transaction.set(postRef, {'likes': FieldValue.increment(1)},
            SetOptions(merge: true));
      }
    });
  }

  /// Crea una nueva publicación.
  Future<void> createPost({
    required String authorId,
    required String text,
  }) async {
    final postRef = _db.collection('Publicacion').doc();

    // Crear el documento en la colección 'Publicacion'.
    await postRef.set({
      'autorID': authorId,
      'texto': text,
      'fecha': FieldValue.serverTimestamp(),
      'likes': 0,
      'comentarios': 0,
      'publico': true,
      'reacciones': {},
      'compartidas': 0,
    });

    // Incrementar el contador de posts del usuario.
    final userRef = _db.collection('Usuarios').doc(authorId);
    await userRef.update({'publicaciones': FieldValue.increment(1)});
  }

  /// Añade un comentario a una publicación.
  Future<void> addComment({
    required String postId,
    required String autorId,
    required String autorNombre,
    required String texto,
  }) async {
    final postRef = _db.collection('Publicacion').doc(postId);
    final commentsRef = postRef.collection('Comentarios');

    await _db.runTransaction((transaction) async {
      // 1. Añadir el nuevo comentario
      final newCommentRef = commentsRef.doc();
      transaction.set(newCommentRef, {
        'autorId': autorId,
        'autorNombre': autorNombre,
        'texto': texto,
        'fecha': FieldValue.serverTimestamp(),
      });

      // 2. Incrementar el contador de comentarios en la publicación
      transaction.set(postRef, {'comentarios': FieldValue.increment(1)},
          SetOptions(merge: true));
    });
  }

  /// Obtiene un stream de comentarios para una publicación específica.
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _db
        .collection('Publicacion')
        .doc(postId)
        .collection('Comentarios')
        .orderBy('fecha', descending: false) // Mostrar los más antiguos primero
        .snapshots();
  }

  /// Obtiene los comentarios para una publicación específica.
  Future<List<Comment>> getCommentsForPost(String postId) async {
    try {
      final snapshot = await _db
          .collection('Publicacion')
          .doc(postId)
          .collection('Comentarios')
          .orderBy('fecha',
              descending: false) // Mostrar los más antiguos primero
          .get();
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error al obtener comentarios: $e');
      return [];
    }
  }

  /// Borra un comentario de una publicación.
  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _db.collection('Publicacion').doc(postId);
    final commentRef = postRef.collection('Comentarios').doc(commentId);

    await _db.runTransaction((transaction) async {
      // 1. Borrar el comentario
      transaction.delete(commentRef);

      // 2. Decrementar el contador de comentarios en la publicación
      transaction.set(postRef, {'comentarios': FieldValue.increment(-1)},
          SetOptions(merge: true));
    });
  }

  /// Sube una imagen de perfil a Firebase Storage y devuelve la URL de descarga.
  Future<String> uploadProfileImage(String userId,
      {Uint8List? imageBytes, String contentType = 'image/jpeg'}) async {
    try {
      if (imageBytes == null) throw Exception('No image data provided');

      // Crear una referencia a la ubicación donde se guardará la imagen.
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Metadata con tipo de contenido
      final metadata = SettableMetadata(contentType: contentType);

      // Subir los bytes (compatible con web y móvil).
      final uploadTask = await ref.putData(imageBytes, metadata);

      // Obtener la URL de descarga.
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error al subir la imagen de perfil: $e');
      throw Exception('No se pudo subir la imagen.');
    }
  }

  /// Actualiza las estadísticas (puntos y racha) de un usuario en Firestore.
  Future<void> updateUserStats(
      String userId, int newPoints, int newStreak) async {
    try {
      final userRef = _db.collection('Usuarios').doc(userId);
      await userRef.update({
        'totalPoints': newPoints,
        'streak': newStreak,
      });
    } catch (e) {
      debugPrint('Error al actualizar estadísticas del usuario: $e');
    }
  }

  /// Restablece el progreso de un usuario en Firestore.
  Future<void> resetUserProgress(String userId) async {
    final userRef = _db.collection('Usuarios').doc(userId);
    await userRef.update({
      'level': 1,
      'totalPoints': 0,
      'streak': 0,
      // Opcional: También podrías querer borrar el historial de entrenamientos
      // que estaría en otra colección. Por ahora, solo reseteamos los contadores.
    });
  }

  /// Método auxiliar para obtener múltiples perfiles de autor eficientemente.
  Future<Map<String, UserProfile>> _getAuthorProfiles(
      List<String> authorIds) async {
    if (authorIds.isEmpty) return {};
    final Map<String, UserProfile> profiles = {};
    try {
      // Firestore limita las consultas 'in' a 30 elementos.
      // Si tienes más, necesitarás dividir la lista en trozos.
      final chunks = <List<String>>[];
      for (var i = 0; i < authorIds.length; i += 30) {
        chunks.add(authorIds.sublist(
            i, i + 30 > authorIds.length ? authorIds.length : i + 30));
      }

      for (final chunk in chunks) {
        final snapshot = await _db
            .collection('Usuarios')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snapshot.docs) {
          profiles[doc.id] = UserProfile.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo perfiles de autor: $e');
    }
    return profiles;
  }

  /// Obtiene el ranking de usuarios ordenados por puntos totales.
  ///
  /// NOTA DE ÍNDICE: Para que esta consulta funcione, se necesita un índice compuesto
  /// en Firestore para la colección `Usuarios`.
  ///
  /// Campos del índice (crear desde el enlace del error o manualmente):
  /// 1. `publico` (Ascendente)
  /// 2. `totalPoints` (Descendente)
  Future<List<UserProfile>> getUsersRanking({int limit = 50}) async {
    try {
      // Esta consulta ya es segura contra usuarios eliminados.
      // Al obtener los perfiles directamente de la colección 'Usuarios', si un usuario es eliminado, no aparecerá en el ranking.
      final snapshot = await _db
          .collection('Usuarios')
          .where('publico',
              isEqualTo: true) // Solo usuarios públicos en el ranking
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener el ranking de usuarios: $e');
      // Asegúrate de crear el índice en Firestore si ves un error aquí.
      return [];
    }
  }

  /// Obtiene la lista de retos disponibles desde Firestore.
  Future<List<Challenge>> getAvailableChallenges({int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection('Challenges')
          // Podrías añadir un .where() para filtrar por retos activos o no expirados
          .orderBy('rewardPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error al obtener los retos: $e');
      return [];
    }
  }

  /// === NUEVAS FUNCIONES SOCIALES ===

  /// Agrega una reacción a una publicación
  Future<void> addReactionToPost(String postId, String userId, String reaction) async {
    final postRef = _db.collection('Publicacion').doc(postId);
    await postRef.update({
      'reacciones.$reaction': FieldValue.arrayUnion([userId])
    }).catchError((e) {
      // Si el campo no existe, lo creamos
      postRef.update({
        'reacciones': {reaction: [userId]}
      });
    });
  }

  /// Elimina una reacción de una publicación
  Future<void> removeReactionFromPost(String postId, String userId, String reaction) async {
    final postRef = _db.collection('Publicacion').doc(postId);
    await postRef.update({
      'reacciones.$reaction': FieldValue.arrayRemove([userId])
    });
  }

  /// Compartir una publicación (guardarla como favorita)
  Future<void> sharePost(String userId, String postId) async {
    final userRef = _db.collection('Usuarios').doc(userId);
    await userRef.update({
      'publicacionesCompartidas': FieldValue.arrayUnion([postId])
    }).catchError((e) {
      userRef.set({'publicacionesCompartidas': [postId]}, SetOptions(merge: true));
    });
  }

  /// Obtener publicaciones compartidas (guardadas) del usuario
  Future<List<Post>> getSharedPosts(String userId) async {
    try {
      final userDoc = await _db.collection('Usuarios').doc(userId).get();
      if (!userDoc.exists) return [];

      final sharedPostIds = List<String>.from(userDoc.get('publicacionesCompartidas') ?? []);
      if (sharedPostIds.isEmpty) return [];

      final postsSnapshot = await _db
          .collection('Publicacion')
          .where(FieldPath.documentId, whereIn: sharedPostIds)
          .get();

      final posts = <Post>[];
      for (var doc in postsSnapshot.docs) {
        final autorId = doc.get('autorID');
        final authorDoc = await _db.collection('Usuarios').doc(autorId).get();
        final author = authorDoc.exists
            ? UserProfile.fromFirestore(authorDoc)
            : null;
        posts.add(Post.fromFirestore(doc, author));
      }
      return posts;
    } catch (e) {
      debugPrint('Error al obtener publicaciones compartidas: $e');
      return [];
    }
  }

  /// Seguir a un usuario
  Future<void> followUser(String userId, String targetUserId) async {
    final followingRef = _db
        .collection('Usuarios')
        .doc(userId)
        .collection('userFollowing')
        .doc(targetUserId);

    final followersRef = _db
        .collection('Usuarios')
        .doc(targetUserId)
        .collection('userFollowers')
        .doc(userId);

    await followingRef.set({'timestamp': FieldValue.serverTimestamp()});
    await followersRef.set({'timestamp': FieldValue.serverTimestamp()});

    // Incrementar contadores
    await _db.collection('Usuarios').doc(userId).update({
      'siguiendo': FieldValue.increment(1)
    }).catchError((_) {
      _db.collection('Usuarios').doc(userId).set(
          {'siguiendo': 1}, SetOptions(merge: true));
    });

    await _db.collection('Usuarios').doc(targetUserId).update({
      'seguidores': FieldValue.increment(1)
    }).catchError((_) {
      _db.collection('Usuarios').doc(targetUserId).set(
          {'seguidores': 1}, SetOptions(merge: true));
    });
  }

  /// Dejar de seguir a un usuario
  Future<void> unfollowUser(String userId, String targetUserId) async {
    final followingRef = _db
        .collection('Usuarios')
        .doc(userId)
        .collection('userFollowing')
        .doc(targetUserId);

    final followersRef = _db
        .collection('Usuarios')
        .doc(targetUserId)
        .collection('userFollowers')
        .doc(userId);

    await followingRef.delete();
    await followersRef.delete();

    // Decrementar contadores
    await _db.collection('Usuarios').doc(userId).update({
      'siguiendo': FieldValue.increment(-1)
    });

    await _db.collection('Usuarios').doc(targetUserId).update({
      'seguidores': FieldValue.increment(-1)
    });
  }

  /// Obtener el número de seguidores de un usuario
  Future<int> getFollowerCount(String userId) async {
    try {
      final followersSnapshot = await _db
          .collection('Usuarios')
          .doc(userId)
          .collection('userFollowers')
          .count()
          .get();
      return followersSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error al obtener conteo de seguidores: $e');
      return 0;
    }
  }

  /// Obtener el número de usuarios que sigue un usuario
  Future<int> getFollowingCount(String userId) async {
    try {
      final followingSnapshot = await _db
          .collection('Usuarios')
          .doc(userId)
          .collection('userFollowing')
          .count()
          .get();
      return followingSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error al obtener conteo de siguiendo: $e');
      return 0;
    }
  }

  /// Obtener publicaciones de un reto/desafío (si existen)
  Future<List<Post>> getChallengePosts(String challengeId) async {
    try {
      final snapshot = await _db
          .collection('Publicacion')
          .where('reto_id', isEqualTo: challengeId)
          .orderBy('fecha', descending: true)
          .get();

      final posts = <Post>[];
      for (var doc in snapshot.docs) {
        final autorId = doc.get('autorID');
        final authorDoc = await _db.collection('Usuarios').doc(autorId).get();
        final author = authorDoc.exists
            ? UserProfile.fromFirestore(authorDoc)
            : null;
        posts.add(Post.fromFirestore(doc, author));
      }
      return posts;
    } catch (e) {
      debugPrint('Error al obtener publicaciones del reto: $e');
      return [];
    }
  }

  /// Mencionar a usuarios en un comentario
  Future<void> addMentionNotification(String userId, String postId, String mention) async {
    final notificationRef = _db.collection('Usuarios').doc(userId).collection('mentions').doc();
    await notificationRef.set({
      'postId': postId,
      'madeBy': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'leido': false,
    });
  }

  /// Obtener notificaciones de menciones
  Future<List<Map<String, dynamic>>> getMentionNotifications(String userId) async {
    try {
      final snapshot = await _db
          .collection('Usuarios')
          .doc(userId)
          .collection('mentions')
          .where('leido', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error al obtener menciones: $e');
      return [];
    }
  }
}

/// NOTA SOBRE ÍNDICES DE FIRESTORE:
/// Para que la consulta de búsqueda de usuarios funcione (`searchPublicUsers`),
/// necesitarás crear un índice compuesto en tu base de datos de Firestore.
///
/// 1. Ve a tu consola de Firebase -> Firestore Database -> Índices.
/// 2. Crea un nuevo índice para la colección `Usuarios`.
/// 3. Añade los siguientes campos en este orden:
///    - `publico` (Ascendente)
///    - `nombre_lowercase` (Ascendente)
///
/// Firebase suele proporcionar un enlace en el mensaje de error en la consola de depuración para crear el índice automáticamente.

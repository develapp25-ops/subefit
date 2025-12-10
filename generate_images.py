#!/usr/bin/env python3
"""
Script para generar imágenes de ejercicios usando PIL
Genera 3 imágenes por ejercicio (inicio, movimiento, final)
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Crear carpeta si no existe
EXERCISES_DIR = "/home/estevan/Escritorio/subefit/assets/exercises"
os.makedirs(EXERCISES_DIR, exist_ok=True)

def draw_stick_figure(draw, x, y, arm_angle=0, leg_angle=0, title=""):
    """Dibuja una figura de palitos en posición específica"""
    
    # Colores
    bg_color = "#f5f5f5"
    line_color = "#333333"
    accent_color = "#e74c3c"
    
    # Head
    head_r = 15
    draw.ellipse([x-head_r, y-head_r, x+head_r, y+head_r], fill="#fdbcb4", outline=line_color, width=2)
    
    # Body
    draw.line([(x, y+head_r), (x, y+head_r+50)], fill=line_color, width=8)
    
    # Arms
    if arm_angle == 0:  # Extended horizontal
        draw.line([(x, y+head_r+15), (x-40, y+head_r+35)], fill=line_color, width=7)
        draw.line([(x, y+head_r+15), (x+40, y+head_r+35)], fill=line_color, width=7)
    elif arm_angle == 1:  # Bent down
        draw.line([(x, y+head_r+15), (x-35, y+head_r+60)], fill=line_color, width=7)
        draw.line([(x, y+head_r+15), (x+35, y+head_r+60)], fill=line_color, width=7)
    
    # Legs
    if leg_angle == 0:  # Extended
        draw.line([(x, y+head_r+50), (x-20, y+head_r+100)], fill=line_color, width=7)
        draw.line([(x, y+head_r+50), (x+20, y+head_r+100)], fill=line_color, width=7)
    elif leg_angle == 1:  # Bent
        draw.line([(x, y+head_r+50), (x-15, y+head_r+80)], fill=line_color, width=7)
        draw.line([(x, y+head_r+50), (x+15, y+head_r+80)], fill=line_color, width=7)
    
    # Draw ground line
    draw.line([(20, 250), (380, 250)], fill="#999", width=2)
    
    # Draw title
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
    except:
        font = ImageFont.load_default()
    
    draw.text((150, 280), title, fill="#333", font=font, anchor="mm")

def generate_exercise_images(exercise_name, positions):
    """
    Genera 3 imágenes para un ejercicio
    positions: lista de (arm_angle, leg_angle, description)
    """
    for idx, (arm_angle, leg_angle, description) in enumerate(positions):
        # Crear imagen
        img = Image.new('RGB', (400, 320), color='#f5f5f5')
        draw = ImageDraw.Draw(img)
        
        # Dibujar figura
        draw_stick_figure(draw, 200, 80, arm_angle=arm_angle, leg_angle=leg_angle, title=description)
        
        # Guardar
        filename = f"{EXERCISES_DIR}/{exercise_name}_{idx+1}.png"
        img.save(filename)
        print(f"✓ Creado: {filename}")

# Definir ejercicios y sus posiciones
exercises = {
    "pushups": [
        (0, 0, "Posición Inicial (Arriba)"),
        (1, 0, "Bajada (Media)"),
        (0, 0, "Subida (Completa)"),
    ],
    "squats": [
        (0, 0, "De pie (Inicio)"),
        (0, 1, "Bajada (Media)"),
        (0, 0, "Levantarse (Final)"),
    ],
    "lunges": [
        (0, 0, "Posición Inicial"),
        (0, 1, "Lunge (Bajada)"),
        (0, 0, "Retorno (Final)"),
    ],
    "plank": [
        (0, 0, "Plancha (Frente)"),
        (0, 0, "Plancha (Media)"),
        (0, 0, "Plancha (Completa)"),
    ],
    "burpees": [
        (0, 0, "De pie (Inicio)"),
        (1, 1, "Flexión (Abajo)"),
        (0, 0, "Salto (Final)"),
    ],
    "crunches": [
        (1, 0, "Acostado (Inicio)"),
        (1, 0, "Crunch (Media)"),
        (1, 0, "Crunch (Completa)"),
    ],
    "mountain_climbers": [
        (0, 0, "Plancha (Inicio)"),
        (0, 1, "Movimiento (Media)"),
        (0, 0, "Alternado (Final)"),
    ],
    "bicycle_crunches": [
        (1, 1, "Inicio (Acostado)"),
        (1, 1, "Movimiento (Media)"),
        (1, 1, "Alternado (Final)"),
    ],
}

# Generar imágenes para cada ejercicio
print("Generando imágenes de ejercicios...")
for exercise, positions in exercises.items():
    generate_exercise_images(exercise, positions)

print("\n✅ ¡Todas las imágenes generadas!")
print(f"📁 Guardadas en: {EXERCISES_DIR}")
print(f"📊 Total: {len(exercises)} ejercicios × 3 imágenes = {len(exercises)*3} imágenes")

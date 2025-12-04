# Guardián del Palafito

## 🎮 Resumen del Juego

**Guardián del Palafito** es un juego de **plataformas 2D de supervivencia** que fusiona la resistencia histórica **Huilliche** con la conservación ambiental contemporánea.

El tema central y mensaje del juego es: **"destinado a perder, pero la resistencia importa"**. El desafío es honrar la lucha, midiendo cuánto tiempo puede mantenerse viva la resistencia contra la opresión.

### Contexto y Ambientación
* **Narrativa:** Inspirado en la **Rebelión Huilliche de 1712** en Chiloé contra los encomenderos españoles. La resistencia renace en criaturas nativas que enfrentan especies invasoras, una metáfora del legado destructivo del colonialismo.
* **Ubicación:** Se desarrolla en los paisajes característicos del **archipiélago de Chiloé**, recreando sus bosques nativos, costas y terrenos montañosos.
* **Personaje Principal:** Un **zorro de Darwin** (*Lycalopex fulvipes*), una especie endémica y amenazada, que viste un *makuñ* tradicional mapuche.
* **Enemigos:** **Especies invasoras antropomórficas** vestidas como conquistadores españoles del siglo XVI-XVII, como la **Rata Conquistadora**, el **Perro Arcabucero**, el **Gato Encomendero** y el **Jabalí Capitán**.

### Jugabilidad y Mecánicas
* **Género:** Plataformas, roguelike, acción.
* **Mecánica Base:** Movilidad bidimensional (izquierda/derecha y salto) en un sistema de plataformas.
* **Progresión:** El jugador comienza en nivel 1 con un ataque único y desbloquea hasta 3 o 4 ataques adicionales (ligeros, pesados, etc.) al subir de nivel y derrotar enemigos. La dificultad escala progresivamente, aumentando las estadísticas y el número de enemigos.
* **Gestión:** El jugador utiliza una barra de ítems para guardar recursos estratégicos como recuperación de vida/defensas y mejoras temporales.
* **Controles:** Requiere una **pantalla táctil** con dos joysticks (uno para movimiento, otro para ataque/apuntar), un botón de salto y botones circulares para ítems/habilidades.

---

## 🌐 Conectividad (Modo Online)

La modalidad en línea se enfoca en la competencia indirecta entre jugadores.

* **Objetivo:** El jugador busca **sabotear** y derrotar al jugador contrincante mientras avanza en su propia partida.
* **Emparejamiento:** El juego busca automáticamente a otro jugador en línea al presionar el botón de inicio.
* **Mecánica de Sabotaje:** Al alcanzar un hito de enemigos eliminados, se envía una señal de "sabotaje" al oponente.
	* **Efectos:** El jugador afectado experimenta contratiempos temporales como **debuffs**, un **mayor número de enemigos**, o enemigos que generan **mayor daño**.
* **Condición de Victoria:** Se consigue al ser el **último jugador con vida** en la ronda.

---

## 🛠️ Desarrollo

| Categoría | Detalle | Fuente |
| :--- | :--- | :--- |
| **Motor de Juego** | **Godot Engine** (versión *opensource*) |
| **Herramienta Visual** | **Pixelorama** (versión *opensuse*) |
| **Control de Versiones** | **GitHub** |
| **Clasificación Prevista** | PEGI 7 |
| **Plataformas** | **Play Store** (Android) |

---

## 👨‍🏫 Información del Curso
 Este proyecto es parte de la **Escuela de Ingeniería UCN Coquimbo**.

### Equipo: Nexus four
* **Valentina Castillo Pardo**
* **Angel Iriarte Castillo**
* **Nicolás Rojas Bustos**
* **Benjamin Bustamante Lopez**

| Detalle | Información |
| :--- | :--- |
| **Docente** | Bastian Ruiz |

---

## 📚 Documentación Técnica

### Sistema de Persistencia

#### Autoload Global (`scripts/global.gd`)
El singleton `Global` gestiona el estado del jugador y estadísticas permanentes.

**Variables de Sesión:**
- `player_health`: Salud actual del jugador
- `player_coins`: Monedas recolectadas en la sesión
- `player_last_position`: Última posición segura

**Récords Permanentes:**
- `best_coins_record`: Mejor puntuación de monedas
- `total_enemies_killed`: Máximo de enemigos eliminados

**Funciones Principales:**
- `save_player_data()`: Guarda progreso actual
- `reset_player_data()`: Resetea sesión al iniciar nueva partida
- `update_stats_on_death()`: Actualiza récords al morir
- `get_stats()`: Retorna estadísticas para UI

**Persistencia:** Los récords se guardan en `user://player_stats.cfg` usando `ConfigFile`.

---

### Sistema del Jugador

#### Script Principal (`scripts/player/player.gd`)

**Constantes:**
- `MAX_HEALTH = 200`
- `SPEED = 170.0`
- `JUMP_VELOCITY = -350.0`
- `MAX_JUMPS = 2` (doble salto)

**Variables Clave:**
- `health`: Salud actual
- `coins`: Monedas recolectadas
- `enemies_killed_this_run`: Contador de enemigos eliminados

**Señales:**
- `health_changed(current, max)`: Actualiza HUD de vida
- `coin_changed(new_coins)`: Actualiza HUD de monedas

**Mecánicas:**
- Sistema de doble salto
- Detección de daño por colisión con enemigos (8-16% de vida según tipo)
- Detección de tiles dañinos (capa de física 2)
- Sistema de invulnerabilidad temporal
- Auto-guardado cada 2 segundos

---

### Sistema de Enemigos

#### Clase Base (`scripts/enemies/enemy_father.gd`)

**Exports Configurables:**
```gdscript
@export var speed = 100
@export var max_health = 100
@export_enum("Básico:1", "Medio:2", "Fuerte:3") var enemy_type = 1
@export var damage_from_attack = 25
@export var coin_reward = 20
```

**Señales:**
- `enemy_died(coin_reward)`: Emitida al morir, conectada por el jugador
- `enemy_damaged(damage, remaining_health)`: Emitida al recibir daño

**Sistema de Detección:**
- `detection_area` (Area2D): Detecta jugador en radio amplio
- `enemy_hitbox` (Area2D): Zona de daño al jugador

**Funciones Heredables:**
- `_custom_behavior()`: Lógica específica del enemigo
- `_on_take_damage()`: Reacción personalizada al daño
- `_get_damage_reduction()`: Reducción de daño en estados especiales

---

### Estructura de Nodos

#### Jugador (`scenes/charactes/player/player.tscn`)
```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── Camera2D
├── player_hit_box (Area2D) - Recibe daño de enemigos
│   └── CollisionShape2D
├── player_attack_hit_box (Area2D) - Detecta enemigos para atacar
│   └── CollisionShape2D
└── Timers
    ├── attack_cooldown
    ├── deal_attack_timer
    ├── player_is_hurt
    ├── invulnerability_timer
    └── regen_timer
```

#### Enemigo Base
```
Enemy (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── detection_area (Area2D)
│   └── CollisionShape2D
├── enemy_hitbox (Area2D)
│   └── CollisionShape2D
└── take_damage_cooldown (Timer)
```

---

### Capas de Física

| Layer | Nombre | Valor | Uso |
|-------|--------|-------|-----|
| 1 | Terreno | `1` | Plataformas, paredes |
| 2 | Terreno Dañino | `2` | Espinas, trampas |
| 3 | Jugador | `4` | CharacterBody2D del jugador |
| 4 | Enemigos | `8` | CharacterBody2D de enemigos |

**Configuración:**
- Jugador: `collision_layer = 4`, `collision_mask = 3` (terreno + dañino)
- Enemigos: `collision_layer = 8`, `collision_mask = 1` (solo terreno)

---

### UI y Menús

#### Menú Principal (`scenes/ui/main_menu.tscn`)
**Estructura requerida para estadísticas:**
```
MainMenu (Control)
└── StatsPanel (Panel)
    └── StatsVBox (VBoxContainer)
        ├── BestCoinsValue (Label)
        └── EnemiesValue (Label)
```

#### Menú de Pausa (`scenes/ui/PausaMenu.tscn`)
- Pausa el juego con `get_tree().paused`
- Botón "Salir" resetea estadísticas del jugador
- Botón "Reiniciar" recarga la escena actual

---

### Flujo de Datos por Run

**Al Iniciar Nivel:**
1. Jugador carga salud/monedas desde `Global`
2. Contador de enemigos inicia en 0

**Durante Partida:**
1. Auto-guardado cada 2 segundos
2. Guardado inmediato al recoger monedas
3. Guardado al recibir daño
4. Incremento de contador al matar enemigos

**Al Morir:**
1. Guardar récords si superan los mejores
2. Mostrar pantalla de muerte

**Al Salir al Menú:**
1. Resetear salud/monedas/contador
2. Mantener récords permanentes

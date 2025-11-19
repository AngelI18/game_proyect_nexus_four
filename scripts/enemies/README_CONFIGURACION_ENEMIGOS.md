# 🎮 Guía Completa del Sistema de Enemigos

## 📋 Tabla de Contenidos
1. [Arquitectura del Sistema](#-arquitectura-del-sistema-padre-hijo)
2. [Sistema de Tipos y Daño](#-sistema-de-tipos-de-enemigos-y-daño)
3. [Variables y Propiedades](#-variables-y-propiedades-de-enemybase)
4. [Funciones del Padre](#-funciones-heredables-de-enemybase)
5. [Sistema de Señales](#-sistema-de-señales)
6. [Configuración de Colisiones](#-sistema-de-capas-de-colisión)
7. [Crear un Enemigo Nuevo](#-cómo-crear-un-enemigo-nuevo)
8. [Templates y Ejemplos](#-templates-de-código)
9. [Errores Comunes](#-errores-comunes-y-soluciones)

---

## 🏛️ Arquitectura del Sistema: Padre-Hijo

### Clase Padre: `EnemyBase` (enemy_father.gd)

`EnemyBase` es la **clase base** que contiene toda la lógica común de enemigos. Todos los enemigos deben heredar de esta clase usando `extends EnemyBase`.

#### ✅ Responsabilidades del Padre:

| Sistema | Descripción | ¿Editable? |
|---------|-------------|------------|
| **Detección** | Detecta al jugador (detection_area) | ❌ Automático |
| **Salud** | Maneja vida, muerte, barra de HP | ❌ Automático |
| **Daño** | Recibe y calcula daño, reducción | ⚙️ Configurable |
| **Knockback** | Retroceso al recibir daño | ⚙️ Configurable |
| **Salto** | Sistema completo de salto | ⚙️ Activable |
| **Señales** | enemy_died, enemy_damaged | ❌ Automático |
| **Dirección** | Sistema de bloqueo de dirección | ⚙️ Activable |
| **Colisiones** | Detección de terreno/jugador | ✅ Funciones útiles |

#### 🚫 Lo que NO debes hacer en el Padre:
- ❌ Modificar enemy_father.gd directamente para un enemigo específico
- ❌ Cambiar la lógica de daño o detección base
- ❌ Alterar el sistema de señales

#### ✅ Lo que SÍ debes hacer:
- ✅ Heredar con `extends EnemyBase`
- ✅ Configurar variables @export en `_ready()`
- ✅ Implementar `_handle_movement()` y `_handle_animation()`
- ✅ Override funciones virtuales si necesitas comportamiento especial

---

### Clases Hijas: Enemigos Específicos

Los enemigos específicos (como `enemy.gd`, `jabali_carga.gd`) son **clases hijas** que:

```gdscript
extends EnemyBase  # ← SIEMPRE heredar del padre

# Tu código específico aquí
```

#### ✅ Responsabilidades de los Hijos:

| Tarea | Obligatorio | Descripción |
|-------|-------------|-------------|
| Configurar estadísticas | ✅ Sí | speed, max_health, enemy_type, etc. |
| Implementar movimiento | ✅ Sí | `_handle_movement(delta)` |
| Implementar animaciones | ✅ Sí | `_handle_animation()` |
| Estados personalizados | ❌ Opcional | enum State { IDLE, WALK, ATTACK } |
| Comportamiento especial | ❌ Opcional | Override otras funciones virtuales |

---

## 🎯 Sistema de Tipos de Enemigos y Daño

### Concepto de Tipos

El sistema usa **tipos de enemigos** que determinan cuánto **daño hacen al jugador** (NO cuánto daño reciben).

| Tipo | Nombre | Daño al Jugador | Uso Recomendado |
|------|--------|-----------------|-----------------|
| **1** | Básico | 8% de MAX_HEALTH del jugador (16 HP) | Enemigos comunes, swarms |
| **2** | Medio | 12% de MAX_HEALTH del jugador (24 HP) | Enemigos especiales, mini-bosses |
| **3** | Fuerte | 16% de MAX_HEALTH del jugador (32 HP) | Bosses, enemigos élite |

### ¿Cómo funciona?

**En el enemigo:**
```gdscript
func _ready() -> void:
    enemy_type = 2  # ← Tipo 2 = Medio (12% de daño)
    super._ready()
```

**En el jugador (automático):**
```gdscript
# El jugador calcula el daño basado en enemy_type
match enemy.get_enemy_type():
    1: damage = int(MAX_HEALTH * 0.08)  # 200 * 0.08 = 16 HP
    2: damage = int(MAX_HEALTH * 0.12)  # 200 * 0.12 = 24 HP
    3: damage = int(MAX_HEALTH * 0.16)  # 200 * 0.16 = 32 HP
```

**IMPORTANTE:** El daño al jugador es **porcentual**, NO un valor fijo. Esto mantiene el balance del juego.

### Variable `damage_from_attack`

Esta variable es diferente: define cuánto **daño RECIBE** el enemigo del jugador.

```gdscript
damage_from_attack = 25  # ← El enemigo recibe 25 HP de daño por ataque del jugador
```

---

## 📊 Variables y Propiedades de EnemyBase

### 1️⃣ Variables @export (Configurables)

#### **Categoría: Estadísticas Básicas**

```gdscript
@export var speed = 100
# Velocidad de movimiento horizontal
# Recomendado: 80-120 (lentos), 120-180 (medios), 180-250 (rápidos)

@export var max_health = 100
# Salud máxima del enemigo
# Recomendado: 50-100 (tipo 1), 100-200 (tipo 2), 200-500 (tipo 3)

@export_enum("Básico:1", "Medio:2", "Fuerte:3") var enemy_type = 1
# Tipo de enemigo que determina el daño al jugador
# 1 = 8% daño, 2 = 12% daño, 3 = 16% daño

@export var damage_from_attack = 25
# Daño que RECIBE del ataque del jugador
# Recomendado: 15-25 (tipo 1), 20-35 (tipo 2), 30-50 (tipo 3)

@export var coin_reward = 20
# Monedas que otorga al morir
# Recomendado: 10-20 (tipo 1), 30-50 (tipo 2), 100-200 (tipo 3)
```

#### **Categoría: Sistema de Combate**

```gdscript
@export var knockback_strength = 200.0
# Fuerza del retroceso al recibir daño
# Recomendado: 150-250

@export var knockback_duration = 0.3
# Duración del retroceso en segundos
# Recomendado: 0.2-0.4

@export var lock_direction_on_attack = false
# Si true, el enemigo NO sigue al jugador durante ataques
# Útil para enemigos con cargas o ataques direccionales
# Usar con lock_attack_direction() y unlock_attack_direction()
```

#### **Categoría: Sistema de Salto**

```gdscript
@export var can_enemy_jump = false
# Habilita/deshabilita el sistema de salto
# false por defecto, activar solo si el enemigo necesita saltar

@export var jump_velocity = -300.0
# Fuerza del salto (negativo = hacia arriba)
# Recomendado: -250 a -400

@export var jump_height_min = 10.0
# Altura mínima para considerar saltar (en píxeles)
# Evita saltos innecesarios por pequeñas diferencias

@export var jump_height_max = 48.0
# Altura máxima que puede saltar (en píxeles)
# Por defecto 48 = ~2 tiles de 24px

@export var jump_horizontal_max = 150.0
# Distancia horizontal máxima para saltar
# Evita saltos a plataformas muy lejanas

@export var jump_cooldown = 0.5
# Tiempo mínimo entre saltos (segundos)
# Evita spam de saltos
```

---

### 2️⃣ Variables Internas (Automáticas - NO modificar directamente)

```gdscript
var health = 0
# Salud actual, se inicializa con max_health automáticamente

var player = null
# Referencia al nodo del jugador, detectado automáticamente

var player_chase = false
# true cuando el jugador está en detection_area

var player_in_attack_zone = false
# true cuando el jugador está en enemy_hitbox

var can_take_damage = true
# Controlado por take_damage_cooldown, evita daño múltiple

var is_taking_knockback = false
# true durante el retroceso, bloquea movimiento

var attack_direction = 0
# Dirección guardada para ataques (-1, 0, 1)

var is_attacking = false
# true cuando lock_attack_direction() está activo

var can_jump = true
# Controlado por jump_timer, evita spam de saltos

var jump_timer = 0.0
# Timer interno del cooldown de salto
```

---

### 3️⃣ Señales

```gdscript
signal enemy_died(coin_reward: int)
# Se emite cuando el enemigo muere
# Parámetro: cantidad de monedas a otorgar

signal enemy_damaged(damage_amount: int, remaining_health: int)
# Se emite cada vez que el enemigo recibe daño
# Parámetros: daño recibido, salud restante
```

**Uso desde otros scripts:**
```gdscript
enemy.enemy_died.connect(_on_enemy_died)
enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_died(coins: int):
    print("Enemigo murió, otorgó ", coins, " monedas")

func _on_enemy_damaged(damage: int, health: int):
    spawn_damage_number(damage)  # Mostrar número flotante
```

---

## 🔧 Funciones Heredables de EnemyBase

### 🔴 Funciones Virtuales (Override Obligatorio/Recomendado)

#### **Inicialización**

```gdscript
func _on_ready() -> void:
    # Llamado DESPUÉS de que el padre inicialice todo
    # Úsalo para inicializar variables específicas del enemigo
    # Ejemplo: current_state = State.IDLE
```

#### **Movimiento (OBLIGATORIO)**

```gdscript
func _handle_movement(delta: float) -> void:
    # Define cómo se mueve el enemigo
    # Debes modificar velocity.x según tu IA
    # El padre llama a move_and_slide() automáticamente
    
    # Implementación por defecto (si no haces override):
    if player_chase and is_on_floor():
        var direction = get_direction_to_player()
        velocity.x = direction * speed
        update_sprite_direction(direction)
    else:
        velocity.x = 0
```

#### **Animaciones (OBLIGATORIO)**

```gdscript
func _handle_animation() -> void:
    # Cambia las animaciones según el estado del enemigo
    # Usa animated_sprite.play("nombre_animacion")
    
    # Implementación por defecto (si no haces override):
    if abs(velocity.x) > 0:
        animated_sprite.play("walk")
    else:
        animated_sprite.play("idle")
```

---

### 🟢 Funciones de Eventos (Override Opcional)

```gdscript
func _on_take_damage(damage_amount: int, is_attack: bool) -> void:
    # Llamado después de recibir daño
    # Úsalo para reacciones especiales (cancelar estados, etc.)
    # Parámetros:
    #   damage_amount: daño final aplicado (después de reducción)
    #   is_attack: true si fue ataque del jugador, false si fue colisión

func _on_death() -> void:
    # Llamado cuando health <= 0
    # Por defecto: emite señal, da monedas, destruye enemigo
    # Override solo para efectos especiales ANTES de morir
    # IMPORTANTE: Llama super._on_death() si haces override

func _on_player_detected(body: Node2D) -> void:
    # Llamado cuando el jugador entra en detection_area
    # player_chase ya está en true automáticamente

func _on_player_lost(body: Node2D) -> void:
    # Llamado cuando el jugador sale de detection_area
    # player_chase ya está en false automáticamente

func _on_attack_zone_entered(body: Node2D) -> void:
    # Llamado cuando el jugador entra en enemy_hitbox
    # player_in_attack_zone ya está en true automáticamente

func _on_attack_zone_exited(body: Node2D) -> void:
    # Llamado cuando el jugador sale de enemy_hitbox
    # player_in_attack_zone ya está en false automáticamente

func _get_damage_reduction() -> float:
    # Retorna 0.0 a 1.0 (porcentaje de reducción de daño)
    # Útil para estados especiales (carga, escudo, etc.)
    # Ejemplo: return 0.6  # Reduce 60% del daño
    # Por defecto: return 0.0  # Sin reducción
```

---

### 🔵 Funciones del Sistema de Salto

#### **Salto Básico (Obstáculos)**

```gdscript
func should_jump_to_reach_player() -> bool
```
**Descripción:** Verifica si debe saltar para alcanzar al jugador que está en una plataforma superior con un obstáculo bloqueando el camino.

**Requisitos:**
- `can_enemy_jump = true`
- Estar en el suelo (`is_on_floor()`)
- Jugador más alto que el enemigo
- Obstáculo detectado mediante raycast

**Retorna:** `true` si debe saltar

**Uso:**
```gdscript
if should_jump_to_reach_player():
    perform_jump()
```

---

#### **Salto a Plataforma Superior (Nuevo)**

```gdscript
func should_jump_to_higher_platform(random_jump_chance: float = 0.015) -> bool
```
**Descripción:** Lógica inteligente para saltar a plataformas superiores donde está el jugador.

**Parámetros:**
- `random_jump_chance`: Probabilidad (0.0-1.0) de saltar si el jugador está en el aire. Default: 0.015 (1.5%)

**Lógica:**
1. Si el jugador está en una **plataforma** → Llama a `should_jump_to_reach_player()` (salta si hay obstáculo)
2. Si el jugador está en el **aire** → Probabilidad baja configurable (evita saltos innecesarios)

**Retorna:** `true` si debe intentar saltar

**Uso:**
```gdscript
# Enemigo conservador (solo salta si jugador está en plataforma)
if should_jump_to_higher_platform():
    perform_jump()

# Enemigo agresivo (50% de chance incluso si jugador está en aire)
if should_jump_to_higher_platform(0.50):
    perform_jump()
```

---

#### **Ejecutar Salto**

```gdscript
func perform_jump() -> void
```
**Descripción:** Ejecuta el salto modificando `velocity.y` y activando el cooldown.

**Uso:**
```gdscript
perform_jump()  # ¡Así de simple!
```

---

### 🟣 Funciones de Detección y Utilidades

#### **Detección de Terreno (Nuevo)**

```gdscript
func is_colliding_with_terrain() -> bool
```
**Descripción:** Verifica si está chocando con **terreno real** (Layer 1), no con el jugador u otros enemigos.

**Uso:** Distinguir colisiones con paredes vs colisiones con entidades.

**Retorna:** `true` si hay colisión con TileMapLayer o StaticBody2D en Layer 1

**Ejemplo:**
```gdscript
# Durante una carga
if is_colliding_with_terrain():
    # Chocó con pared, hacer retroceso
    apply_wall_stun()
# Si choca con jugador, is_on_wall() sería true pero esto sería false
```

---

#### **Detección de Jugador en Plataforma (Nuevo)**

```gdscript
func is_player_on_platform() -> bool
```
**Descripción:** Verifica si el jugador está en el suelo (no saltando/cayendo).

**Retorna:** `true` si el jugador está en una plataforma

**Ejemplo:**
```gdscript
if height_diff > 50:
    if is_player_on_platform():
        # Jugador está en plataforma superior estable, saltar
        perform_jump()
    else:
        # Jugador solo está saltando, no perseguir en aire
        velocity.x = 0
```

---

#### **Dirección hacia el Jugador**

```gdscript
func get_direction_to_player() -> int
```
**Retorna:** `-1` (izquierda), `1` (derecha), `0` (sin jugador)

**Uso:**
```gdscript
var dir = get_direction_to_player()
velocity.x = dir * speed
```

---

### 🟡 Sistema de Bloqueo de Dirección

Útil para enemigos con ataques direccionales (cargas, lanzas, etc.) que NO deben seguir al jugador una vez iniciado el ataque.

#### **Bloquear Dirección**

```gdscript
func lock_attack_direction() -> void
```
**Descripción:** Guarda la dirección actual hacia el jugador en `attack_direction` y actualiza `flip_h`.

**Uso:**
```gdscript
# Al iniciar un ataque de carga
func _start_charge():
    lock_attack_direction()  # Guarda dirección
    current_state = State.CHARGING
```

---

#### **Desbloquear Dirección**

```gdscript
func unlock_attack_direction() -> void
```
**Descripción:** Libera la dirección bloqueada, permitiendo seguir al jugador nuevamente.

**Uso:**
```gdscript
# Al terminar el ataque
func _end_charge():
    unlock_attack_direction()
    current_state = State.IDLE
```

---

#### **Obtener Dirección de Movimiento**

```gdscript
func get_movement_direction() -> int
```
**Descripción:** Retorna la dirección correcta según el estado de bloqueo.

**Lógica:**
- Si `is_attacking` y `lock_direction_on_attack = true` → Retorna `attack_direction` (bloqueada)
- Caso contrario → Retorna `get_direction_to_player()` (sigue al jugador)

**Uso:**
```gdscript
var dir = get_movement_direction()
velocity.x = dir * speed
```

---

#### **Actualizar Sprite con Dirección**

```gdscript
func update_sprite_direction(direction: int) -> void
```
**Descripción:** Actualiza `flip_h` del sprite SOLO si la dirección NO está bloqueada.

**Uso:**
```gdscript
var dir = get_direction_to_player()
update_sprite_direction(dir)  # Solo actualiza si no está atacando
```

---

### 🔴 Funciones de Combate

#### **Recibir Daño**

```gdscript
func take_damage(damage_amount: int, is_attack: bool = false) -> void
```
**Parámetros:**
- `damage_amount`: Cantidad de daño base
- `is_attack`: `true` si es ataque del jugador, `false` si es colisión

**Lógica interna:**
1. Llama a `_get_damage_reduction()` (override en hijos)
2. Calcula daño final: `damage * (1.0 - reducción)`
3. Aplica daño, inicia cooldown, knockback, feedback visual
4. Emite señal `enemy_damaged`
5. Si `health <= 0`, llama a `_on_death()`

**Uso:** Normalmente NO necesitas llamar esto directamente (automático), pero puedes:
```gdscript
take_damage(50, false)  # Daño por trampa, lava, etc.
```

---

#### **Aplicar Knockback**

```gdscript
func apply_knockback() -> void
```
**Descripción:** Aplica retroceso alejándose del jugador.

**Lógica:** Calcula dirección opuesta al jugador, aplica `knockback_strength` durante `knockback_duration`.

**Uso:** Llamado automáticamente por `take_damage()`, pero puedes forzarlo:
```gdscript
apply_knockback()  # Retroceso manual
```

---

#### **Obtener Tipo de Enemigo**

```gdscript
func get_enemy_type() -> int
```
**Retorna:** `1`, `2`, o `3`

**Uso:** El jugador llama esto para calcular el daño a recibir.

---

#### **Identificador de Enemigo**

```gdscript
func enemy() -> void
```
**Descripción:** Función vacía usada para identificar enemigos con `has_method("enemy")`.

---

## 📡 Sistema de Señales

### signal `enemy_died(coin_reward: int)`

**Cuándo se emite:** Cuando `health <= 0` en `_on_death()`

**Parámetros:**
- `coin_reward`: Cantidad de monedas configurada en el enemigo

**Usos:**
- Sistema de estadísticas (enemigos eliminados)
- Spawn de power-ups/ítems
- Logros y objetivos
- Efectos especiales de muerte

**Conexión:**
```gdscript
# En un GameManager o similar
func _ready():
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.enemy_died.connect(_on_any_enemy_died)

func _on_any_enemy_died(coins: int):
    total_kills += 1
    total_coins_earned += coins
    check_level_objectives()
```

---

### signal `enemy_damaged(damage_amount: int, remaining_health: int)`

**Cuándo se emite:** Cada vez que el enemigo recibe daño

**Parámetros:**
- `damage_amount`: Daño final aplicado (después de reducción)
- `remaining_health`: Salud restante del enemigo

**Usos:**
- Números flotantes de daño
- Sonidos/efectos de impacto
- Animaciones de reacción
- Estadísticas de combate

**Conexión:**
```gdscript
# En un VFXManager
func _ready():
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(damage: int, health: int):
    spawn_damage_number(damage)
    play_hit_sound()
    if health < 30:
        show_low_health_indicator()
```

---

## 🎨 Sistema de Capas de Colisión

### Tabla de Capas

| Layer | Nombre | Entidades | Valor Godot |
|-------|--------|-----------|-------------|
| **1** | Terreno | TileMapLayer, plataformas, paredes | `1` |
| **2** | Terreno Dañino | Espinas, lava, trampas | `2` |
| **3** | Jugador | CharacterBody2D del jugador | `4` |
| **4** | Enemigos | CharacterBody2D de enemigos | `8` |

**IMPORTANTE:** En Godot, los valores de layers son potencias de 2:
- Layer 1 = `1` (2^0)
- Layer 2 = `2` (2^1)
- Layer 3 = `4` (2^2)
- Layer 4 = `8` (2^3)

---

### Configuración de Nodos del Enemigo

#### **1. CharacterBody2D (Nodo Raíz)**

```
collision_layer = 8   # Está en Layer 4 (enemigos)
collision_mask = 1    # Solo colisiona con Layer 1 (terreno)
```

**¿Por qué?**
- El enemigo existe en Layer 4 (otros pueden detectarlo)
- Solo colisiona físicamente con terreno (Layer 1)
- NO colisiona con otros enemigos (no incluye 8 en mask)
- NO colisiona con jugador directamente (daño por Area2D)

---

#### **2. detection_area (Area2D)**

```
collision_layer = 0    # No física
collision_mask = 4     # Detecta Layer 3 (jugador)
monitorable = false    # No puede ser detectada
```

**Radio recomendado:** 200-300 píxeles (CircleShape2D)

**Señales a conectar:**
- `body_entered(body)` → `_on_detection_area_body_entered`
- `body_exited(body)` → `_on_detection_area_body_exited`

---

#### **3. enemy_hitbox (Area2D)**

```
collision_layer = 8    # Está en Layer 4 (enemigos)
collision_mask = 4     # Detecta Layer 3 (jugador)
```

**Señales a conectar:**
- `area_entered(area)` → `_on_enemy_hitbox_area_entered`
- `area_exited(area)` → `_on_enemy_hitbox_area_exited`

**IMPORTANTE:** Detecta `player_attack_hit_box` (Area2D del jugador), NO el CharacterBody2D.

---

#### **4. take_damage_cooldown (Timer)**

```
wait_time = 0.5
one_shot = true
autostart = false
```

**Señal a conectar:**
- `timeout()` → `_on_take_damage_cooldown_timeout`

---

#### **5. health_bar (ProgressBar) - Opcional**

```
max_value = 100  # Igual a max_health
value = 100
visible = false  # Se muestra automáticamente al recibir daño
```

---

## 🏗️ Cómo Crear un Enemigo Nuevo (Paso a Paso)

Esta sección te guiará paso a paso para crear un enemigo completamente funcional desde cero.

---

### 📋 Paso 1: Crear la Escena Base

#### 1.1 Crear el Nodo Raíz

1. En Godot, ve a **Scene → New Scene**
2. Haz clic en **Other Node**
3. Busca y selecciona **CharacterBody2D**
4. Haz clic en **Create**
5. Renombra el nodo a un nombre descriptivo (ej: `Goblin`, `Zombie`, `Flying_Eye`)

#### 1.2 Configurar Collision del CharacterBody2D

**CRÍTICO:** Estos valores DEBEN estar exactamente así para que funcione.

1. Selecciona el nodo raíz (CharacterBody2D)
2. En el **Inspector**, busca la sección **Collision**
3. Configura:
   ```
   Collision Layer: Solo marcar Layer 4
   Collision Mask:  Solo marcar Layer 1
   ```

**Visualmente en el Inspector:**
```
┌─ Collision ──────────────────────┐
│ Collision Layer:                 │
│ [ ] 1  [ ] 2  [ ] 3  [✓] 4      │  ← SOLO Layer 4 marcado
│ [ ] 5  [ ] 6  [ ] 7  [ ] 8      │
│                                  │
│ Collision Mask:                  │
│ [✓] 1  [ ] 2  [ ] 3  [ ] 4      │  ← SOLO Layer 1 marcado
│ [ ] 5  [ ] 6  [ ] 7  [ ] 8      │
└──────────────────────────────────┘
```

**¿Por qué estos valores?**
- **Layer 4 (valor 8)**: El enemigo "existe" en esta capa, otros pueden detectarlo
- **Mask Layer 1 (valor 1)**: El enemigo solo colisiona físicamente con el terreno
- **NO incluir Layer 4 en mask**: Los enemigos NO chocan entre sí

---

### 📋 Paso 2: Agregar el Sprite Animado

#### 2.1 Crear AnimatedSprite2D

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **AnimatedSprite2D**
3. Haz clic en **Create**
4. El nombre DEBE ser exactamente: `AnimatedSprite2D` (sin renombrar)

#### 2.2 Configurar Animaciones

1. Selecciona el nodo **AnimatedSprite2D**
2. En el Inspector, busca **Animation → Sprite Frames**
3. Haz clic en **[empty]** → **New SpriteFrames**
4. Haz clic en el icono de SpriteFrames para abrirlo

**En el panel de SpriteFrames:**
1. Por defecto hay una animación "default", renómbrala a **"idle"**
2. Haz clic en **Add Animation** para agregar:
   - **"walk"** (obligatorio)
   - **"attack"** (opcional)
   - **"jump"** (opcional si can_enemy_jump = true)
   - **"death"** (opcional)

3. Para cada animación, arrastra los sprites correspondientes

**Configuración recomendada:**
```
idle:  3-6 frames, loop activado, FPS 5-8
walk:  4-8 frames, loop activado, FPS 8-12
attack: 4-6 frames, loop activado, FPS 10-15
jump:  1-3 frames, loop desactivado, FPS 5
```

---

### 📋 Paso 3: Agregar Collision Shape del Cuerpo

#### 3.1 Crear CollisionShape2D

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **CollisionShape2D**
3. Haz clic en **Create**
4. El nombre DEBE ser: `CollisionShape2D`

#### 3.2 Configurar la Forma

1. Selecciona el **CollisionShape2D**
2. En el Inspector, busca **Shape**
3. Haz clic en **[empty]** → Selecciona un tipo:
   - **CapsuleShape2D** (recomendado para humanoides)
   - **RectangleShape2D** (para enemigos cuadrados/rectangulares)
   - **CircleShape2D** (para enemigos redondos)

4. **Ajusta el tamaño** para que coincida con el sprite:
   - El shape debe cubrir el cuerpo del enemigo
   - NO debe ser demasiado grande (causaría colisiones raras)
   - NO debe ser demasiado pequeño (el jugador pasaría a través)

**Ejemplo para un humanoide de 48x48:**
```
CapsuleShape2D:
  Radius: 12
  Height: 36
```

---

### 📋 Paso 4: Crear detection_area (Detección del Jugador)

Esta área detecta cuando el jugador está cerca para comenzar a perseguirlo.

#### 4.1 Crear el Nodo Area2D

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **Area2D**
3. Haz clic en **Create**
4. Renombra a exactamente: `detection_area` (**importante: en minúsculas**)

#### 4.2 Configurar Collision del detection_area

**CRÍTICO:** Estos valores son diferentes al CharacterBody2D.

1. Selecciona `detection_area`
2. En el Inspector, busca **Collision**
3. Configura:
   ```
   Collision Layer: Ninguno marcado (todos desmarcados)
   Collision Mask:  Solo marcar Layer 3
   ```

**Visualmente:**
```
┌─ Collision ──────────────────────┐
│ Collision Layer:                 │
│ [ ] 1  [ ] 2  [ ] 3  [ ] 4      │  ← NINGUNO marcado
│                                  │
│ Collision Mask:                  │
│ [ ] 1  [ ] 2  [✓] 3  [ ] 4      │  ← SOLO Layer 3 marcado
└──────────────────────────────────┘
```

4. Busca la propiedad **Monitorable** y desmárcala:
   ```
   Monitorable: false  ← IMPORTANTE
   ```

**¿Por qué?**
- **Layer vacío**: El área no ocupa espacio físico
- **Mask Layer 3**: Solo detecta al jugador (que está en Layer 3)
- **Monitorable false**: Otros no pueden detectar esta área

#### 4.3 Agregar CollisionShape2D al detection_area

1. Click derecho en `detection_area` → **Add Child Node**
2. Busca **CollisionShape2D**
3. Haz clic en **Create**

4. Selecciona este nuevo CollisionShape2D
5. En Inspector → **Shape** → **CircleShape2D**
6. Configura el **Radius**:
   ```
   Radius: 200-300 (para enemigos normales)
   Radius: 400-500 (para enemigos con largo rango)
   ```

**Tip:** El círculo rojo que aparece en el editor muestra el área de detección.

#### 4.4 Conectar Señales del detection_area

**MUY IMPORTANTE:** Sin estas señales, el enemigo NO detectará al jugador.

1. Selecciona el nodo `detection_area`
2. Ve a la pestaña **Node** (al lado de Inspector)
3. Haz doble clic en la señal **body_entered(body: Node2D)**
4. En la ventana que aparece:
   - **Receiver Method**: Escribe `_on_detection_area_body_entered`
   - Haz clic en **Connect**

5. Repite para la señal **body_exited(body: Node2D)**:
   - **Receiver Method**: `_on_detection_area_body_exited`
   - Haz clic en **Connect**

---

### 📋 Paso 5: Crear enemy_hitbox (Zona de Daño al Jugador)

Esta área detecta cuando el jugador está en rango para recibir daño.

#### 5.1 Crear el Nodo Area2D

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **Area2D**
3. Haz clic en **Create**
4. Renombra a exactamente: `enemy_hitbox` (**importante: en minúsculas**)

#### 5.2 Configurar Collision del enemy_hitbox

1. Selecciona `enemy_hitbox`
2. En el Inspector, busca **Collision**
3. Configura:
   ```
   Collision Layer: Solo marcar Layer 4
   Collision Mask:  Solo marcar Layer 3
   ```

**Visualmente:**
```
┌─ Collision ──────────────────────┐
│ Collision Layer:                 │
│ [ ] 1  [ ] 2  [ ] 3  [✓] 4      │  ← SOLO Layer 4 marcado
│                                  │
│ Collision Mask:                  │
│ [ ] 1  [ ] 2  [✓] 3  [ ] 4      │  ← SOLO Layer 3 marcado
└──────────────────────────────────┘
```

**¿Por qué?**
- **Layer 4**: Permite que el jugador detecte al enemigo
- **Mask Layer 3**: Detecta el área de ataque del jugador (player_attack_hit_box)

#### 5.3 Agregar CollisionShape2D al enemy_hitbox

1. Click derecho en `enemy_hitbox` → **Add Child Node**
2. Busca **CollisionShape2D**
3. Haz clic en **Create**

4. Selecciona este nuevo CollisionShape2D
5. En Inspector → **Shape** → Elige el mismo tipo que el cuerpo:
   - **CapsuleShape2D** (si el cuerpo es cápsula)
   - **RectangleShape2D** (si el cuerpo es rectángulo)

6. **Ajusta para que sea ligeramente más grande que el CollisionShape2D del cuerpo**:
   ```
   Ejemplo si el cuerpo es Capsule(12, 36):
   enemy_hitbox debería ser Capsule(14, 38)
   ```

**Tip:** El área de daño debe ser un poco más grande para que el jugador no necesite estar exactamente encima.

#### 5.4 Conectar Señales del enemy_hitbox

**CRÍTICO:** Estas señales son diferentes, usan `area_entered`, NO `body_entered`.

1. Selecciona el nodo `enemy_hitbox`
2. Ve a la pestaña **Node**
3. Haz doble clic en **area_entered(area: Area2D)**
4. En la ventana:
   - **Receiver Method**: `_on_enemy_hitbox_area_entered`
   - Haz clic en **Connect**

5. Repite para **area_exited(area: Area2D)**:
   - **Receiver Method**: `_on_enemy_hitbox_area_exited`
   - Haz clic en **Connect**

**¿Por qué area_entered y no body_entered?**
- El sistema de ataque del jugador usa un **Area2D** llamado `player_attack_hit_box`
- Por eso detectamos áreas, no cuerpos

---

### 📋 Paso 6: Crear take_damage_cooldown (Timer)

Este timer evita que el enemigo reciba daño múltiples veces por frame.

#### 6.1 Crear el Timer

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **Timer**
3. Haz clic en **Create**
4. Renombra a exactamente: `take_damage_cooldown` (**importante: en minúsculas**)

#### 6.2 Configurar el Timer

1. Selecciona `take_damage_cooldown`
2. En el Inspector, configura:
   ```
   Wait Time: 0.5
   One Shot: true (marcado)
   Autostart: false (desmarcado)
   ```

**Visualmente:**
```
┌─ Timer ──────────────────────────┐
│ Wait Time: 0.5                   │
│ [✓] One Shot                     │
│ [ ] Autostart                    │
└──────────────────────────────────┘
```

#### 6.3 Conectar Señal del Timer

1. Selecciona `take_damage_cooldown`
2. Ve a la pestaña **Node**
3. Haz doble clic en **timeout()**
4. En la ventana:
   - **Receiver Method**: `_on_take_damage_cooldown_timeout`
   - Haz clic en **Connect**

---

### 📋 Paso 7: Crear health_bar (Barra de Salud) - Opcional

Esta barra muestra la salud del enemigo visualmente.

#### 7.1 Crear el ProgressBar

1. Click derecho en el nodo raíz → **Add Child Node**
2. Busca **ProgressBar**
3. Haz clic en **Create**
4. Renombra a exactamente: `health_bar` (**importante: en minúsculas**)

#### 7.2 Configurar el ProgressBar

1. Selecciona `health_bar`
2. En el Inspector:
   ```
   Min Value: 0
   Max Value: 100  (debe coincidir con max_health)
   Value: 100
   Show Percentage: false
   Visible: false  (se mostrará automáticamente al recibir daño)
   ```

3. **Posición y Tamaño:**
   ```
   Transform → Position:
     X: -20  (centrado sobre el enemigo)
     Y: -40  (encima de la cabeza)
   
   Transform → Size:
     X: 40
     Y: 6
   ```

4. **Estilo Visual (opcional):**
   - En Inspector → **Theme Overrides → Styles**
   - Puedes personalizar los colores de la barra aquí

---

### 📋 Paso 8: Adjuntar el Script

#### 8.1 Crear el Script

1. Click derecho en el nodo raíz (CharacterBody2D)
2. Selecciona **Attach Script**
3. En la ventana de crear script:
   ```
   Language: GDScript
   Inherits: EnemyBase  ← CAMBIAR ESTO (por defecto dice CharacterBody2D)
   Template: Empty
   Path: res://scripts/enemies/nombre_enemigo.gd
   ```
4. Haz clic en **Create**

#### 8.2 Usar un Template

Ahora edita el script y copia uno de los **Templates de Código** de las secciones siguientes según tu necesidad:
- **Template 1**: Enemigo básico sin estados
- **Template 2**: Enemigo con estados (IDLE, WALK, ATTACK)
- **Template 3**: Enemigo con salto
- **Template 4**: Enemigo con reducción de daño

---

### 📋 Paso 9: Verificación Final

Antes de probar, verifica esta **checklist**:

#### ✅ Estructura de Nodos
```
NombreEnemigo (CharacterBody2D)
├── AnimatedSprite2D ✓
├── CollisionShape2D ✓
├── detection_area (Area2D) ✓
│   └── CollisionShape2D (CircleShape2D) ✓
├── enemy_hitbox (Area2D) ✓
│   └── CollisionShape2D ✓
├── take_damage_cooldown (Timer) ✓
└── health_bar (ProgressBar) ✓ (opcional)
```

#### ✅ Collision Layers
| Nodo | Collision Layer | Collision Mask |
|------|-----------------|----------------|
| Raíz (CharacterBody2D) | 4 ✓ | 1 ✓ |
| detection_area | Ninguno ✓ | 3 ✓ |
| enemy_hitbox | 4 ✓ | 3 ✓ |

#### ✅ Señales Conectadas
- [ ] `detection_area.body_entered` → `_on_detection_area_body_entered`
- [ ] `detection_area.body_exited` → `_on_detection_area_body_exited`
- [ ] `enemy_hitbox.area_entered` → `_on_enemy_hitbox_area_entered`
- [ ] `enemy_hitbox.area_exited` → `_on_enemy_hitbox_area_exited`
- [ ] `take_damage_cooldown.timeout` → `_on_take_damage_cooldown_timeout`

#### ✅ Propiedades Especiales
- [ ] `detection_area.monitorable = false`
- [ ] `take_damage_cooldown.one_shot = true`
- [ ] `take_damage_cooldown.wait_time = 0.5`
- [ ] `health_bar.visible = false` (si existe)

#### ✅ Script
- [ ] Hereda de `EnemyBase`
- [ ] Configura `enemy_type` (1, 2 o 3)
- [ ] Llama a `super._ready()` al final de `_ready()`
- [ ] Implementa `_handle_movement(delta)`
- [ ] Implementa `_handle_animation()`

---

### 📋 Paso 10: Guardar y Probar

1. **Guardar escena:** Ctrl+S
   - Guárdala en `res://scenes/characters/enemies/nombre_enemigo.tscn`

2. **Probar:**
   - Agrega la escena del enemigo a un nivel de prueba
   - Presiona F6 para correr la escena
   - Verifica:
     - ✓ El enemigo cae al suelo (gravedad funciona)
     - ✓ Cuando te acercas, comienza a perseguirte
     - ✓ Al atacarlo, recibe daño y retrocede
     - ✓ Al tocarlo, el jugador recibe daño
     - ✓ Al morir, desaparece y da monedas

3. **Ajustes comunes:**
   - Si el enemigo va muy lento/rápido: ajusta `speed` en el script
   - Si el área de detección es muy pequeña/grande: ajusta el radius del CircleShape2D de `detection_area`
   - Si el daño es muy bajo/alto: ajusta `enemy_type` (1, 2 o 3)

---

## 🖼️ Diagrama Visual de Configuración

```
┌─────────────────────────────────────────────────────────────┐
│ ENEMIGO (CharacterBody2D)                                   │
│ collision_layer: 4 (enemigos)                               │
│ collision_mask: 1 (terreno)                                 │
│                                                             │
│ ┌──────────────┐  ┌───────────────────────────────────┐   │
│ │AnimatedSprite│  │ CollisionShape2D (Cuerpo)         │   │
│ │  idle, walk, │  │ - CapsuleShape2D / RectangleShape │   │
│ │  attack, jump│  │ - Tamaño ajustado al sprite       │   │
│ └──────────────┘  └───────────────────────────────────┘   │
│                                                             │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ detection_area (Area2D)                                │ │
│ │ collision_layer: 0, collision_mask: 3                  │ │
│ │ monitorable: false                                     │ │
│ │                                                        │ │
│ │  ┌───────────────────────────────┐                    │ │
│ │  │ CollisionShape2D              │                    │ │
│ │  │ - CircleShape2D (radius 250)  │                    │ │
│ │  │ - Área grande de detección    │                    │ │
│ │  └───────────────────────────────┘                    │ │
│ │                                                        │ │
│ │  Señales:                                              │ │
│ │  • body_entered → _on_detection_area_body_entered      │ │
│ │  • body_exited → _on_detection_area_body_exited        │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ enemy_hitbox (Area2D)                                  │ │
│ │ collision_layer: 4, collision_mask: 3                  │ │
│ │                                                        │ │
│ │  ┌───────────────────────────────┐                    │ │
│ │  │ CollisionShape2D              │                    │ │
│ │  │ - Mismo tipo que el cuerpo    │                    │ │
│ │  │ - Ligeramente más grande      │                    │ │
│ │  └───────────────────────────────┘                    │ │
│ │                                                        │ │
│ │  Señales:                                              │ │
│ │  • area_entered → _on_enemy_hitbox_area_entered        │ │
│ │  • area_exited → _on_enemy_hitbox_area_exited          │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ take_damage_cooldown (Timer)                           │ │
│ │ wait_time: 0.5, one_shot: true                         │ │
│ │                                                        │ │
│ │  Señal:                                                │ │
│ │  • timeout → _on_take_damage_cooldown_timeout          │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ health_bar (ProgressBar) - Opcional                    │ │
│ │ max_value: 100, visible: false                         │ │
│ └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Tips y Consejos

### 🎯 Ajustar el Tamaño de Detección

**Problema:** El enemigo te detecta desde muy lejos/cerca

**Solución:**
1. Selecciona `detection_area → CollisionShape2D`
2. En Inspector → Shape → Circle → **Radius**
3. Ajusta el valor:
   - Radius 150-200: Detección cercana (enemigos pasivos)
   - Radius 250-350: Detección media (enemigos normales)
   - Radius 400-500: Detección lejana (enemigos agresivos)

### 🎯 Ajustar el Área de Daño

**Problema:** El jugador recibe daño desde muy lejos/tiene que estar muy cerca

**Solución:**
1. Selecciona `enemy_hitbox → CollisionShape2D`
2. Ajusta el tamaño del shape para que sea:
   - Ligeramente más grande que el sprite = daño generoso
   - Del mismo tamaño que el sprite = daño preciso
   - Ligeramente más pequeño = el jugador debe tocar el centro

### 🎯 Enemigos que se Caen del Borde

**Problema:** Los enemigos caminan y caen de las plataformas

**Solución:** Implementar detección de bordes en el script:
```gdscript
func _handle_movement(_delta: float) -> void:
    if not player or not is_on_floor():
        velocity.x = 0
        return
    
    # Raycast para detectar borde
    var space_state = get_world_2d().direct_space_state
    var direction = get_direction_to_player()
    var check_pos = global_position + Vector2(direction * 20, 10)
    
    var query = PhysicsRayQueryParameters2D.create(check_pos, check_pos + Vector2(0, 20))
    query.collision_mask = 1
    var result = space_state.intersect_ray(query)
    
    # Si no hay suelo adelante, detenerse
    if result.is_empty():
        velocity.x = 0
        return
    
    # Continuar normalmente
    velocity.x = direction * speed
    update_sprite_direction(direction)
```

---

### Paso 2: Crear el Script (.gd)

Usa los templates de la siguiente sección según la complejidad del enemigo.

---

## 📝 Templates de Código

### Template 1: Enemigo Básico (Sin Estados)

**Uso:** Enemigos simples que solo persiguen al jugador

```gdscript
extends EnemyBase

# Clase: Nombre del Enemigo
# Tipo: 1 (Básico)
# Comportamiento: Persigue al jugador, ataque por contacto

func _ready() -> void:
	# Configuración tipo 1 (básico)
	enemy_type = 1
	speed = 100
	max_health = 80
	damage_from_attack = 20
	coin_reward = 15
	knockback_strength = 200.0
	
	# Salto deshabilitado
	can_enemy_jump = false
	
	super._ready()

func _on_ready() -> void:
	pass  # Inicialización específica si es necesaria

func _handle_movement(_delta: float) -> void:
	if not player or not is_on_floor():
		velocity.x = 0
		return
	
	var direction = get_direction_to_player()
	
	if player_chase:
		velocity.x = direction * speed
		update_sprite_direction(direction)
	else:
		velocity.x = 0

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	if abs(velocity.x) > 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
```

---

### Template 2: Enemigo con Estados (Sin Salto)

**Uso:** Enemigos con comportamiento más complejo (idle, patrulla, ataque)

```gdscript
extends EnemyBase

# Estados del enemigo
enum State { IDLE, WALK, ATTACK, COOLDOWN }
var current_state = State.IDLE
var attack_timer = 0.0
var cooldown_timer = 0.0

@export var attack_duration = 1.0
@export var attack_cooldown = 2.0

func _ready() -> void:
	# Configuración tipo 2 (medio)
	enemy_type = 2
	speed = 120
	max_health = 150
	damage_from_attack = 25
	coin_reward = 35
	knockback_strength = 250.0
	
	can_enemy_jump = false
	
	super._ready()

func _on_ready() -> void:
	current_state = State.IDLE

func _handle_movement(delta: float) -> void:
	# Actualizar timers
	if attack_timer > 0:
		attack_timer -= delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	match current_state:
		State.IDLE:
			_state_idle()
		State.WALK:
			_state_walk()
		State.ATTACK:
			_state_attack()
		State.COOLDOWN:
			_state_cooldown()

func _state_idle() -> void:
	velocity.x = 0
	if player_chase:
		current_state = State.WALK

func _state_walk() -> void:
	if not player:
		current_state = State.IDLE
		return
	
	var direction = get_direction_to_player()
	velocity.x = direction * speed
	update_sprite_direction(direction)
	
	if player_in_attack_zone and cooldown_timer <= 0:
		current_state = State.ATTACK
		attack_timer = attack_duration

func _state_attack() -> void:
	velocity.x = 0
	
	if attack_timer <= 0:
		current_state = State.COOLDOWN
		cooldown_timer = attack_cooldown

func _state_cooldown() -> void:
	velocity.x = 0
	
	# Mirar al jugador durante cooldown
	if player:
		var direction = get_direction_to_player()
		update_sprite_direction(direction)
	
	if cooldown_timer <= 0:
		if player_chase:
			current_state = State.WALK
		else:
			current_state = State.IDLE

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALK:
			animated_sprite.play("walk")
		State.ATTACK:
			animated_sprite.play("attack")
		State.COOLDOWN:
			animated_sprite.play("idle")
```

---

### Template 3: Enemigo Avanzado (Con Salto)

**Uso:** Enemigos que pueden saltar a plataformas superiores

```gdscript
extends EnemyBase

enum State { IDLE, WALK, ATTACK, JUMP }
var current_state = State.IDLE

func _ready() -> void:
	# Configuración tipo 2 (medio)
	enemy_type = 2
	speed = 130
	max_health = 180
	damage_from_attack = 30
	coin_reward = 40
	knockback_strength = 250.0
	
	# Habilitar salto
	can_enemy_jump = true
	jump_velocity = -300.0
	jump_height_min = 10.0
	jump_height_max = 120.0
	jump_horizontal_max = 150.0
	jump_cooldown = 2.0
	
	super._ready()

func _on_ready() -> void:
	current_state = State.IDLE

func _handle_movement(_delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle()
		State.WALK:
			_state_walk()
		State.ATTACK:
			_state_attack()
		State.JUMP:
			_state_jump()

func _state_idle() -> void:
	velocity.x = 0
	
	if player:
		var direction = get_direction_to_player()
		update_sprite_direction(direction)
	
	if player_chase:
		current_state = State.WALK

func _state_walk() -> void:
	if not player or not is_on_floor():
		velocity.x = 0
		return
	
	var direction = get_direction_to_player()
	var height_diff = global_position.y - player.global_position.y
	
	# Intentar saltar a plataforma superior
	if height_diff > jump_height_min:
		if should_jump_to_higher_platform():
			perform_jump()
			current_state = State.JUMP
			return
	# O saltar obstáculo al mismo nivel
	elif should_jump_to_reach_player():
		perform_jump()
		current_state = State.JUMP
		return
	
	if player_in_attack_zone:
		current_state = State.ATTACK
		return
	
	velocity.x = direction * speed
	update_sprite_direction(direction)

func _state_attack() -> void:
	velocity.x = 0
	
	if not player_in_attack_zone:
		current_state = State.WALK

func _state_jump() -> void:
	if not player:
		if is_on_floor():
			current_state = State.IDLE
		return
	
	var direction = get_direction_to_player()
	velocity.x = direction * speed
	update_sprite_direction(direction)
	
	if is_on_floor():
		current_state = State.WALK

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALK:
			animated_sprite.play("walk")
		State.ATTACK:
			animated_sprite.play("attack")
		State.JUMP:
			animated_sprite.play("jump")
```

---

### Template 4: Enemigo con Reducción de Daño

**Uso:** Enemigos con estados especiales que reducen daño (escudo, carga, etc.)

```gdscript
extends EnemyBase

enum State { IDLE, WALK, SHIELD, ATTACK }
var current_state = State.IDLE

func _ready() -> void:
	enemy_type = 2
	speed = 100
	max_health = 200
	damage_from_attack = 30
	coin_reward = 50
	knockback_strength = 250.0
	
	super._ready()

# Override reducción de daño
func _get_damage_reduction() -> float:
	# Durante SHIELD, reduce 80% del daño
	if current_state == State.SHIELD:
		return 0.8
	# Durante ATTACK, reduce 30% del daño
	elif current_state == State.ATTACK:
		return 0.3
	return 0.0  # Sin reducción en otros estados

func _handle_movement(_delta: float) -> void:
	# Tu lógica de estados aquí
	match current_state:
		State.IDLE:
			velocity.x = 0
		State.WALK:
			velocity.x = get_direction_to_player() * speed
		State.SHIELD:
			velocity.x = 0  # Inmóvil pero protegido
		State.ATTACK:
			velocity.x = 0

func _handle_animation() -> void:
	if not animated_sprite:
		return
	
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.WALK:
			animated_sprite.play("walk")
		State.SHIELD:
			animated_sprite.play("shield")
		State.ATTACK:
			animated_sprite.play("attack")
```

---

## 🚨 Errores Comunes y Soluciones

### ❌ Error: "El enemigo no recibe daño"

**Síntomas:** El enemigo no pierde vida al atacarlo

**Causas posibles:**
1. Timer `take_damage_cooldown` sin señal `timeout` conectada
2. `enemy_hitbox` con collision_mask incorrecto
3. Variable `can_take_damage` siempre en false

**Soluciones:**
```gdscript
# Verificar en el editor:
# take_damage_cooldown → Signals → timeout → Connected to _on_take_damage_cooldown_timeout

# Verificar en el editor:
# enemy_hitbox → Inspector → Collision Mask = 4 (Layer 3 marcado)

# Verificar que la función existe:
func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
	damage_cooldown.stop()
```

---

### ❌ Error: "El enemigo no detecta al jugador"

**Síntomas:** `player_chase` siempre false, enemigo no persigue

**Causas posibles:**
1. `detection_area` con collision_mask incorrecto
2. Señales de `detection_area` no conectadas
3. Jugador no tiene método `player()`

**Soluciones:**
```gdscript
# Verificar en el editor:
# detection_area → Inspector → Collision Mask = 4 (Layer 3 marcado)
# detection_area → Inspector → Monitorable = false

# Verificar señales conectadas:
# detection_area → Signals → body_entered → _on_detection_area_body_entered
# detection_area → Signals → body_exited → _on_detection_area_body_exited

# Verificar en player.gd:
func player() -> void:
	pass  # Esta función debe existir
```

---

### ❌ Error: "El jugador no recibe daño del enemigo"

**Síntomas:** Colisión con enemigo no reduce HP del jugador

**Causas posibles:**
1. `enemy_hitbox` con collision_mask o layer incorrectos
2. Señales de `enemy_hitbox` no conectadas
3. Sistema de daño del jugador no detecta `enemy_type`

**Soluciones:**
```gdscript
# Verificar en el editor:
# enemy_hitbox → Inspector → Collision Layer = 8 (Layer 4)
# enemy_hitbox → Inspector → Collision Mask = 4 (Layer 3)

# Verificar señales conectadas a area_entered/exited (NO body_entered):
# enemy_hitbox → Signals → area_entered → _on_enemy_hitbox_area_entered
# enemy_hitbox → Signals → area_exited → _on_enemy_hitbox_area_exited

# Verificar que enemy_type está configurado:
func _ready() -> void:
	enemy_type = 2  # ← Debe estar definido
	super._ready()
```

---

### ❌ Error: "Los enemigos se bloquean entre sí"

**Síntomas:** Múltiples enemigos no pueden moverse, se empujan

**Causa:** `collision_mask` del CharacterBody2D incluye Layer 4 (enemigos)

**Solución:**
```gdscript
# En el editor:
# NombreEnemigo (CharacterBody2D) → Inspector → Collision Mask = 1 (SOLO Layer 1)
```

---

### ❌ Error: "El enemigo atraviesa el terreno"

**Síntomas:** Enemigo cae a través de plataformas

**Causa:** `collision_mask` no incluye Layer 1

**Solución:**
```gdscript
# En el editor:
# NombreEnemigo (CharacterBody2D) → Inspector → Collision Mask = 1 (Layer 1 marcado)
```

---

### ❌ Error: "No se llama a super._ready()"

**Síntomas:** Vida no se inicializa, nodos null, comportamiento errático

**Causa:** Olvidar llamar `super._ready()` en clase hija

**Solución:**
```gdscript
func _ready() -> void:
	enemy_type = 2
	speed = 120
	max_health = 150
	# ... resto de configuración
	
	super._ready()  # ← ¡IMPORTANTE! Siempre al final
```

---

### ❌ Error: "El enemigo no hace knockback"

**Síntomas:** Al recibir daño, no retrocede

**Causa:** Variable `player` es null (no detectado)

**Solución:**
```gdscript
# Verificar que detection_area detecta correctamente:
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player = body  # ← Esto debe ejecutarse
		player_chase = true
		print("Jugador detectado: ", player.name)
```

---

### ❌ Error: "Las señales no se emiten"

**Síntomas:** enemy_died o enemy_damaged no se detectan

**Causa:** Señales conectadas incorrectamente o no conectadas

**Solución:**
```gdscript
# Las señales se emiten automáticamente en el padre
# Solo conéctalas desde otro script:

func _ready():
	var enemy = get_node("Enemigo")
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_died(coins: int):
	print("Enemigo murió, ", coins, " monedas")

func _on_enemy_damaged(damage: int, health: int):
	print("Enemigo recibió ", damage, " daño, salud: ", health)
```

---

### ❌ Error: "El sprite no hace flip"

**Síntomas:** Enemigo no voltea al cambiar de dirección

**Causa:** No usar `update_sprite_direction()` o `animated_sprite.flip_h` mal configurado

**Solución:**
```gdscript
func _handle_movement(_delta: float) -> void:
	var direction = get_direction_to_player()
	velocity.x = direction * speed
	update_sprite_direction(direction)  # ← Actualiza flip automáticamente

# O manual:
if animated_sprite and direction != 0:
	animated_sprite.flip_h = direction > 0  # true = derecha, false = izquierda
```

---

## 📚 Ejemplos de Referencia

### Ejemplo Básico: Slime
**Archivos:**
- `scripts/enemies/enemy.gd`
- `scenes/charactes/enemies/enemy.tscn`

**Características:**
- Tipo 1 (8% de daño)
- Movimiento simple (perseguir jugador)
- Sin salto
- Sin estados complejos

---

### Ejemplo Avanzado: Jabalí de Carga
**Archivos:**
- `scripts/enemies/jabali_carga.gd`
- `scenes/charactes/enemies/jabali_carga.tscn`

**Características:**
- Tipo 2 (12% de daño)
- 8 estados (IDLE, WALK, RUN, PREPARE, ATTACK, COOLDOWN, JUMP, WALL_STUN)
- Sistema de carga con preparación y cooldown
- Bloqueo de dirección durante carga (`lock_direction_on_attack = true`)
- Reducción de daño (60% durante ATTACK, 30% durante PREPARE)
- Salto a plataformas superiores
- Detección inteligente de paredes vs jugador
- Retroceso al chocar con paredes

**Sistemas usados:**
- `lock_attack_direction()` / `unlock_attack_direction()`
- `is_colliding_with_terrain()`
- `should_jump_to_higher_platform()`
- `_get_damage_reduction()` override
- Sistema de timers para estados

---

## 🎨 Valores Recomendados por Tipo

### Tipo 1 (Básico) - Enemigos Comunes

```gdscript
enemy_type = 1
speed = 80-120
max_health = 50-100
damage_from_attack = 15-25
coin_reward = 10-20
knockback_strength = 150-200
can_enemy_jump = false  # Normalmente deshabilitado
```

**Ejemplos:** Slime, Zombie, Esqueleto básico

---

### Tipo 2 (Medio) - Enemigos Especiales

```gdscript
enemy_type = 2
speed = 120-180
max_health = 100-250
damage_from_attack = 20-35
coin_reward = 30-60
knockback_strength = 200-300
can_enemy_jump = true   # Activar si es necesario
jump_cooldown = 2.0     # Saltos espaciados
```

**Ejemplos:** Jabalí, Orco, Guardián

---

### Tipo 3 (Fuerte) - Bosses y Élites

```gdscript
enemy_type = 3
speed = 150-250
max_health = 300-800
damage_from_attack = 30-60
coin_reward = 100-300
knockback_strength = 300-500
can_enemy_jump = true
jump_cooldown = 1.0     # Saltos frecuentes
```

**Ejemplos:** Mini-boss, Boss de nivel, Enemigo élite

---

## 🔗 Archivos del Sistema

- **Clase Padre:** `scripts/enemies/enemy_father.gd` (EnemyBase)
- **Ejemplo Básico:** `scripts/enemies/enemy.gd`
- **Ejemplo Avanzado:** `scripts/enemies/jabali_carga.gd`
- **Script del Jugador:** `scripts/player/player.gd`
- **Variable Global:** `scripts/global.gd` (Global.player_current_attack)

---

## ✅ Checklist Completo

### Configuración de Escena (.tscn)

- [ ] CharacterBody2D con nombre descriptivo
- [ ] `collision_layer = 8`, `collision_mask = 1`
- [ ] AnimatedSprite2D con animaciones (mínimo: idle, walk)
- [ ] CollisionShape2D para el cuerpo
- [ ] **detection_area** (Area2D):
  - [ ] `collision_layer = 0`, `collision_mask = 4`, `monitorable = false`
  - [ ] CollisionShape2D (CircleShape2D, radius ~250)
  - [ ] Señales conectadas: `body_entered`, `body_exited`
- [ ] **enemy_hitbox** (Area2D):
  - [ ] `collision_layer = 8`, `collision_mask = 4`
  - [ ] CollisionShape2D (tamaño del cuerpo)
  - [ ] Señales conectadas: `area_entered`, `area_exited`
- [ ] **take_damage_cooldown** (Timer):
  - [ ] `wait_time = 0.5`, `one_shot = true`
  - [ ] Señal conectada: `timeout`
- [ ] *(Opcional)* ProgressBar `health_bar`

### Configuración de Script (.gd)

- [ ] `extends EnemyBase`
- [ ] Configurar `enemy_type` (1, 2 o 3)
- [ ] Configurar estadísticas en `_ready()`
- [ ] Llamar `super._ready()` al final de `_ready()`
- [ ] Implementar `_handle_movement(delta)`
- [ ] Implementar `_handle_animation()`
- [ ] *(Opcional)* Implementar `_on_ready()` para inicialización
- [ ] *(Opcional)* Override funciones virtuales según necesidad

---

**✨ ¡Sistema completo de enemigos con herencia documentado!**

Esta guía cubre todo lo necesario para crear enemigos desde simples hasta muy complejos usando el sistema de herencia de `EnemyBase`.


## 📐 Arquitectura del Sistema: Padre-Hijo

### 🏛️ Clase Padre: `EnemyBase` (enemy_father.gd)

La clase `EnemyBase` es el **padre** de todos los enemigos. Contiene toda la lógica común y **NO debe ser modificada** directamente para crear nuevos enemigos.

#### ✅ Lo que DEBE estar en el Padre:
- Sistema de detección del jugador
- Sistema de daño y salud
- Sistema de knockback
- Sistema de salto (opcional, configurable)
- Manejo de colisiones con áreas
- Sistema de señales (muerte, daño)
- Barra de salud visual
- Feedback de daño (parpadeo rojo)

#### 🔒 Variables que NO se modifican (automáticas):
```gdscript
var health = 0                    # Se calcula de max_health
var player = null                 # Detectado automáticamente
var player_chase = false          # Detectado automáticamente
var player_in_attack_zone = false # Detectado automáticamente
var can_take_damage = true        # Manejado por cooldown
var is_taking_knockback = false   # Manejado automáticamente
var can_jump = true               # Manejado por jump_timer
var jump_timer = 0.0              # Manejado automáticamente
```

#### � Señales del Padre:
```gdscript
signal enemy_died(coin_reward: int)
signal enemy_damaged(damage_amount: int, remaining_health: int)
```

Estas señales se emiten automáticamente y pueden ser conectadas desde otras partes del juego para efectos, logros, etc.

---

### 👶 Clases Hijas: Enemigos Específicos

Las clases hijas (como `enemy.gd` y `jabali_carga.gd`) **heredan** de `EnemyBase` y solo deben:

#### ✅ Lo que DEBE estar en los Hijos:
1. **Configuración de variables @export** en `_ready()`
2. **Implementación de movimiento** en `_handle_movement(delta)`
3. **Implementación de animaciones** en `_handle_animation()`
4. **(Opcional) Comportamiento especial** en otras funciones virtuales

#### 🎯 Variables que SÍ se modifican en Hijos:

```gdscript
# Categoría: Estadísticas Básicas
@export var speed = 100              # Velocidad de movimiento
@export var max_health = 100         # Salud máxima
@export var enemy_type = 1           # TIPO de enemigo (1, 2, 3)
@export var damage_from_attack = 25  # Daño que RECIBE del jugador
@export var coin_reward = 20         # MODIFICAR en hijos

# Categoría: Sistema de Combate
@export var knockback_strength = 200.0
@export var knockback_duration = 0.3

# Categoría: Sistema de Salto (si está habilitado)
@export var can_enemy_jump = false   # true para habilitar salto
@export var jump_velocity = -300.0
@export var jump_height_min = 10.0
@export var jump_height_max = 48.0
@export var jump_horizontal_max = 150.0
@export var jump_cooldown = 0.5
```

---

## 🎯 Sistema de Tipos de Enemigos y Daño

### Tipos de Enemigos

El sistema usa **3 tipos** de enemigos que determinan cuánto daño hacen al jugador:

| Tipo | Nombre | Daño al Jugador | Ejemplo |
|------|--------|-----------------|---------|
| **1** | Básico | 8% de salud máxima del jugador | Slime |
| **2** | Medio | 12% de salud máxima del jugador | Jabalí |
| **3** | Fuerte | 16% de salud máxima del jugador | Boss, enemigos especiales |

### Cálculo de Daño

**El daño al jugador NO se configura manualmente**, se calcula automáticamente:

```gdscript
# Salud máxima del jugador = 200
Tipo 1: 200 * 0.08 = 16 de daño
Tipo 2: 200 * 0.12 = 24 de daño
Tipo 3: 200 * 0.16 = 32 de daño
```

### Configurar el Tipo en el Hijo

```gdscript
extends EnemyBase

func _ready() -> void:
    enemy_type = 2  # Tipo 2 = 12% de daño (medio)
    # ... resto de configuración
    super._ready()
```

**IMPORTANTE:** El sistema de daño es porcentual para mantener el balance del juego.

---

## 📋 Sistema de Capas de Colisión

| Layer | Nombre | Descripción | Valor |
|-------|--------|-------------|-------|
| **1** | Terreno | Plataformas, suelos | 1 |
| **2** | Terreno Dañino | Tiles de daño | 2 |
| **3** | Jugador | Personaje jugador | 4 |
| **4** | Enemigos | Todos los enemigos | 8 |

### Configuración del Enemigo

#### 1️⃣ CharacterBody2D Principal
```gdscript
collision_layer = 8  # Está en Layer 4 (enemigos)
collision_mask = 1   # Solo colisiona con terreno
```

#### 2️⃣ detection_area (Area2D)
```gdscript
collision_layer = 0  # No físico
collision_mask = 4   # Detecta jugador (Layer 3)
monitorable = false
```

#### 3️⃣ enemy_hitbox (Area2D)
```gdscript
collision_layer = 8  # Layer 4 (para que jugador lo detecte)
collision_mask = 4   # Detecta jugador (Layer 3)
```

---

## 🏗️ Estructura de Escena del Enemigo

```
EnemyName (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── detection_area (Area2D)
│   └── CollisionShape2D
├── enemy_hitbox (Area2D)
│   └── CollisionShape2D
├── take_damage_cooldown (Timer)
└── health_bar (ProgressBar)
```

---

## 💻 Template para Crear un Enemigo Nuevo

### Enemigo Básico (Tipo 1)

```gdscript
extends EnemyBase

# Clase: Nombre del Enemigo
# Tipo: 1 (Básico - 8% de daño)
# Comportamiento: Descripción

func _ready() -> void:
    # Configuración de tipo 1 (básico)
    enemy_type = 1  # 8% de daño
    speed = 100
    max_health = 100
    damage_from_attack = 20
    coin_reward = 20
    knockback_strength = 200.0
    
    # Salto deshabilitado por defecto
    can_enemy_jump = false
    
    super._ready()

func _on_ready() -> void:
    # Inicialización específica
    pass

func _handle_movement(_delta: float) -> void:
    if not player or not is_on_floor():
        velocity.x = 0
        return
    
    var direction = sign(player.global_position.x - global_position.x)
    
    if player_chase:
        velocity.x = direction * speed
        if animated_sprite:
            animated_sprite.flip_h = direction < 0
    else:
        velocity.x = 0

func _handle_animation() -> void:
    if not animated_sprite:
        return
    
    if abs(velocity.x) > 0:
        animated_sprite.play("walk")
    else:
        animated_sprite.play("idle")
```

### Enemigo Medio con Estados (Tipo 2)

```gdscript
extends EnemyBase

# Estados del enemigo
enum State { IDLE, WALK, ATTACK, SPECIAL }
var current_state = State.IDLE

func _ready() -> void:
    # Configuración de tipo 2 (medio)
    enemy_type = 2  # 12% de daño
    speed = 120
    max_health = 150
    damage_from_attack = 25
    coin_reward = 35
    knockback_strength = 250.0
    
    # Habilitar salto si es necesario
    can_enemy_jump = true
    jump_velocity = -300.0
    
    super._ready()

func _on_ready() -> void:
    current_state = State.IDLE

func _handle_movement(_delta: float) -> void:
    match current_state:
        State.IDLE:
            velocity.x = 0
            if player_chase:
                current_state = State.WALK
        
        State.WALK:
            if not player:
                current_state = State.IDLE
                return
            
            var direction = sign(player.global_position.x - global_position.x)
            velocity.x = direction * speed
            
            if animated_sprite:
                animated_sprite.flip_h = direction < 0
            
            if player_in_attack_zone:
                current_state = State.ATTACK
        
        State.ATTACK:
            # Lógica de ataque
            if not player_in_attack_zone:
                current_state = State.WALK

func _handle_animation() -> void:
    if not animated_sprite:
        return
    
    match current_state:
        State.IDLE:
            animated_sprite.play("idle")
        State.WALK:
            animated_sprite.play("walk")
        State.ATTACK:
            animated_sprite.play("attack")

# Override para comportamiento especial al recibir daño
func _on_take_damage(_damage_amount: int, _is_attack: bool) -> void:
    # Por ejemplo: cancelar ataque especial
    if current_state == State.SPECIAL:
        current_state = State.WALK
```

---

## 🔧 Funciones Virtuales del Padre

Estas funciones **pueden ser sobrescritas** en las clases hijas:

### Funciones Principales (Override Recomendado)

```gdscript
func _on_ready() -> void:
    # Inicialización específica del enemigo
    # Se llama DESPUÉS de que el padre inicialice todo

func _handle_movement(delta: float) -> void:
    # OBLIGATORIO: Lógica de movimiento del enemigo
    # Debe modificar velocity.x según la IA del enemigo

func _handle_animation() -> void:
    # OBLIGATORIO: Cambiar animaciones según el estado
    # Usar animated_sprite.play("nombre_animacion")
```

### Funciones de Eventos (Override Opcional)

```gdscript
func _on_take_damage(damage_amount: int, is_attack: bool) -> void:
    # Reacción al recibir daño
    # Ejemplo: cambiar de estado, cancelar ataques, etc.

func _on_player_detected(body: Node2D) -> void:
    # Cuando el jugador entra en detection_area
    # Automáticamente activa player_chase = true

func _on_player_lost(body: Node2D) -> void:
    # Cuando el jugador sale de detection_area
    # Automáticamente desactiva player_chase = false

func _on_attack_zone_entered(body: Node2D) -> void:
    # Cuando el jugador entra en enemy_hitbox
    # Automáticamente activa player_in_attack_zone = true

func _on_attack_zone_exited(body: Node2D) -> void:
    # Cuando el jugador sale de enemy_hitbox
    # Automáticamente desactiva player_in_attack_zone = false
```

### Función de Reducción de Daño (Opcional Avanzado)

```gdscript
func _get_damage_reduction() -> float:
    # Retorna un valor de 0.0 a 1.0 (porcentaje de reducción)
    # Ejemplo: durante un estado especial, reducir daño 60%
    if current_state == State.CHARGING:
        return 0.6  # 60% de reducción
    return 0.0  # Sin reducción
```

**Ejemplo de uso:**
- Jabalí en carga: reduce daño 60%
- Escudo activado: reduce daño 80%
- Modo berserk: reduce daño 30%

---

## 🎯 Funciones Heredadas (Listas para Usar)

Estas funciones **ya están implementadas** en el padre y pueden usarse directamente:

### Sistema de Salto

```gdscript
should_jump_to_reach_player() -> bool
    # Verifica si debe saltar para alcanzar al jugador
    # Considera altura y distancia horizontal

perform_jump() -> void
    # Ejecuta el salto (modifica velocity.y)
    # Activa cooldown automáticamente
```

**Ejemplo de uso:**
```gdscript
func _handle_movement(_delta: float) -> void:
    if should_jump_to_reach_player():
        perform_jump()
```

### Sistema de Información

```gdscript
get_enemy_type() -> int
    # Retorna el tipo del enemigo (1, 2 o 3)
    # Usado por el jugador para calcular daño

enemy() -> void
    # Función identificadora vacía
    # Permite detectar si un nodo es enemigo con has_method("enemy")
```

---

## 📊 Señal `enemy_died` - Sistema de Recompensas

La señal `enemy_died` se emite **automáticamente** cuando el enemigo muere:

```gdscript
signal enemy_died(coin_reward: int)
```

### ¿Cómo funciona?

1. El padre emite la señal en `_on_death()`
2. Pasa `coin_reward` como parámetro
3. **Las monedas se dan automáticamente** al jugador
4. Los hijos **solo modifican el valor** de `coin_reward`

### Modificar Recompensa en Hijos

```gdscript
func _ready() -> void:
    enemy_type = 2
    coin_reward = 50  # ← MODIFICAR AQUÍ
    super._ready()
```

**NO necesitas:**
- Override `_on_death()`
- Llamar manualmente a `player.add_coins()`
- Conectar la señal manualmente

**El padre se encarga de todo.**

---

## 📊 Señal `enemy_damaged` - Sistema de Feedback

La señal `enemy_damaged` se emite **cada vez que el enemigo recibe daño**:

```gdscript
signal enemy_damaged(damage_amount: int, remaining_health: int)
```

### Usos posibles:
- Mostrar números flotantes de daño
- Sonidos de impacto
- Efectos de partículas
- Logros/estadísticas

### Conectar desde otro script:

```gdscript
# En un manager de efectos o UI
func _ready():
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(damage: int, health: int):
    # Mostrar número flotante
    spawn_damage_number(damage)
```

---

## ✅ Checklist para Crear un Enemigo

### En el Editor (Escena .tscn):

- [ ] CharacterBody2D con `collision_layer = 8`, `collision_mask = 1`
- [ ] AnimatedSprite2D con animaciones (idle, walk mínimo)
- [ ] CollisionShape2D para el cuerpo
- [ ] **detection_area** (Area2D):
  - [ ] `collision_layer = 0`, `collision_mask = 4`
  - [ ] `monitorable = false`
  - [ ] CollisionShape2D (radio 200-300px)
  - [ ] Conectar `body_entered` y `body_exited` al script
- [ ] **enemy_hitbox** (Area2D):
  - [ ] `collision_layer = 8`, `collision_mask = 4`
  - [ ] CollisionShape2D (tamaño del cuerpo)
  - [ ] Conectar `body_entered` y `body_exited` al script
- [ ] **take_damage_cooldown** (Timer):
  - [ ] `wait_time = 0.5`, `one_shot = true`
  - [ ] Conectar `timeout` al script
- [ ] *(Opcional)* ProgressBar para health_bar

### En el Script (.gd):

- [ ] `extends EnemyBase`
- [ ] Configurar `enemy_type` (1, 2 o 3)
- [ ] Configurar estadísticas en `_ready()`
- [ ] **Llamar `super._ready()`** al final
- [ ] Implementar `_handle_movement(delta)`
- [ ] Implementar `_handle_animation()`
- [ ] *(Opcional)* Override otras funciones virtuales

---

## 🚨 Errores Comunes y Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| Enemigo no recibe daño | Timer sin conectar | Conectar `timeout` de `take_damage_cooldown` |
| No detecta al jugador | Mask incorrecto | `detection_area.collision_mask = 4` |
| Jugador no recibe daño | Mask incorrecto | `enemy_hitbox.collision_mask = 4` |
| Enemigos se bloquean | Mask incluye enemigos | `CharacterBody2D.collision_mask = 1` |
| Atraviesa terreno | Mask sin terreno | `CharacterBody2D.collision_mask = 1` |
| No se emiten señales | Señales sin conectar | Verificar conexiones en editor |
| Daño incorrecto al jugador | Tipo mal configurado | Configurar `enemy_type = 1, 2 o 3` |

---

## 📚 Ejemplos de Referencia

### Ejemplo Básico: Slime (Tipo 1)
**Archivos:**
- `scripts/enemies/enemy.gd`
- `scenes/charactes/enemies/enemy.tscn`

**Características:**
- Movimiento simple (perseguir jugador)
- Sin estados complejos
- Sin salto
- 8% de daño (Tipo 1)

### Ejemplo Avanzado: Jabalí (Tipo 2)
**Archivos:**
- `scripts/enemies/jabali_carga.gd`
- `scenes/charactes/enemies/jabali_carga.tscn`

**Características:**
- 7 estados (IDLE, WALK, RUN, PREPARE, ATTACK, COOLDOWN, JUMP)
- Sistema de carga con preparación
- Salto habilitado
- Reducción de daño durante carga (60%)
- 12% de daño (Tipo 2)
- Velocidades variables por estado

---

## 🎨 Valores Recomendados

### Enemigos Tipo 1 (Básicos)
```gdscript
enemy_type = 1
speed = 80-100
max_health = 50-100
damage_from_attack = 15-20
coin_reward = 10-20
knockback_strength = 150-200
```

### Enemigos Tipo 2 (Medios)
```gdscript
enemy_type = 2
speed = 100-150
max_health = 100-200
damage_from_attack = 20-30
coin_reward = 30-50
knockback_strength = 200-300
can_enemy_jump = true  # Opcional
```

### Enemigos Tipo 3 (Fuertes/Jefes)
```gdscript
enemy_type = 3
speed = 120-200
max_health = 200-500
damage_from_attack = 30-50
coin_reward = 100-200
knockback_strength = 300-400
can_enemy_jump = true
```

---

## 🔗 Archivos del Sistema

- **Clase Padre:** `scripts/enemies/enemy_father.gd` (EnemyBase)
- **Script del Jugador:** `scripts/player/player.gd`
- **Global de Ataque:** `scripts/global.gd` (Global.player_current_attack)

---

## 📝 Resumen de Relación Padre-Hijo

| Aspecto | Padre (EnemyBase) | Hijo (enemy.gd, jabali.gd) |
|---------|-------------------|----------------------------|
| **Señales** | ✅ Define y emite | ❌ No modifica |
| **Sistema de daño** | ✅ Implementado | ❌ No modifica |
| **Sistema de salto** | ✅ Implementado | ✅ Activa con `can_enemy_jump` |
| **Detección** | ✅ Implementado | ❌ No modifica |
| **Knockback** | ✅ Implementado | ❌ No modifica |
| **Estadísticas** | ⚙️ Valores por defecto | ✅ **CONFIGURAR AQUÍ** |
| **Movimiento** | ❌ Virtual (vacío) | ✅ **IMPLEMENTAR** |
| **Animaciones** | ❌ Virtual (vacío) | ✅ **IMPLEMENTAR** |
| **Recompensas** | ✅ Sistema automático | ✅ Solo `coin_reward` |
| **Estados personalizados** | ❌ No tiene | ✅ Crear si es necesario |
| **Reducción daño** | ⚙️ Función base (0%) | ✅ Override si necesario |

**Regla de oro:** 
- El **Padre** maneja la **mecánica**
- El **Hijo** define el **comportamiento**

---

**✨ ¡Sistema completo de enemigos listo para usar!**

````

| Layer | Nombre | Descripción | Valor en Godot |
|-------|--------|-------------|----------------|
| **1** | Terreno | Plataformas, suelos, paredes | 1 |
| **2** | Terreno Dañino | Tiles que hacen daño (espinas, lava, etc.) | 2 |
| **3** | Jugador | El personaje del jugador | 4 |
| **4** | Enemigos | Todos los enemigos del juego | 8 |

### 🔢 Valores en Godot
**IMPORTANTE:** Godot usa valores de potencias de 2 para las capas:
- Layer 1 = Valor `1` (2^0)
- Layer 2 = Valor `2` (2^1)
- Layer 3 = Valor `4` (2^2) ← **Jugador está aquí**
- Layer 4 = Valor `8` (2^3) ← **Enemigos están aquí**

### 🎯 Configuración del Jugador (Referencia)
```
collision_layer = 3  (Layers 1+2 = valores 1+2)
collision_mask = 3   (Detecta Layers 1+2)
```
**Nota:** El jugador usa `collision_layer = 3` que combina las capas 1 y 2.

---

## 🏗️ Estructura de un Enemigo

Todo enemigo debe tener esta estructura de nodos:

```
EnemyName (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D (hitbox del cuerpo)
├── detection_area (Area2D) - Detecta al jugador
│   └── CollisionShape2D
├── enemy_hitbox (Area2D) - Zona de daño al jugador
│   └── CollisionShape2D
├── take_damage_cooldown (Timer)
└── health_bar (ProgressBar) - Opcional
```

---

## ⚙️ Configuración de Collision Layers

### 1️⃣ **CharacterBody2D Principal (Nodo Raíz)**

```gdscript
collision_layer = 8  # El enemigo está en Layer 4 (valor 8)
collision_mask = 1   # Solo colisiona con terreno (Layer 1, valor 1)
```

**¿Por qué?**
- `collision_layer = 8`: Define que el enemigo ESTÁ en Layer 4 (valor binario 8)
- `collision_mask = 1`: Define que solo colisiona con el terreno (Layer 1)
- **NO colisiona con otros enemigos** (no incluye valor 8 en mask)
- **Permite que múltiples enemigos se superpongan** sin bloquearse

---

### 2️⃣ **detection_area (Area2D)**

```gdscript
collision_layer = 0  # No está en ninguna capa
collision_mask = 4   # Detecta al jugador (Layer 3, valor 4)
monitorable = false
```

**¿Por qué?**
- `collision_layer = 0`: El área no ocupa espacio físico
- `collision_mask = 4`: Solo detecta al jugador (Layer 3 = valor 4 en Godot)
- `monitorable = false`: No puede ser detectada por otras áreas

**Señales a conectar:**
- `body_entered(body: Node2D)` → `_on_detection_area_body_entered`
- `body_exited(body: Node2D)` → `_on_detection_area_body_exited`

---

### 3️⃣ **enemy_hitbox (Area2D)**

```gdscript
collision_layer = 8  # Está en Layer 4 (enemigos, valor 8)
collision_mask = 4   # Detecta al jugador (Layer 3, valor 4)
```

**¿Por qué?**
- `collision_layer = 8`: Permite que el jugador detecte al enemigo
- `collision_mask = 4`: Detecta cuando el jugador entra en zona de daño

**Señales a conectar:**
- `body_entered(body: Node2D)` → `_on_enemy_hitbox_body_entered`
- `body_exited(body: Node2D)` → `_on_enemy_hitbox_body_exited`

---

### 4️⃣ **take_damage_cooldown (Timer)**

```gdscript
wait_time = 0.5
one_shot = true
```

**Señal a conectar:**
- `timeout()` → `_on_take_damage_cooldown_timeout`

---

## 💻 Script del Enemigo

### Herencia de EnemyBase

```gdscript
extends EnemyBase

func _ready() -> void:
    # Configuración básica
    speed = 100
    max_health = 100
    damage_to_player = 20
    damage_from_attack = 25  # Daño que RECIBE del jugador
    coin_reward = 20
    knockback_strength = 200.0
    
    # Activar salto (opcional)
    can_enemy_jump = false  # true para habilitar
    jump_velocity = -300.0
    jump_height_min = 10.0
    jump_height_max = 48.0
    jump_horizontal_max = 150.0
    jump_cooldown = 0.5
    
    super._ready()  # IMPORTANTE: Llamar al padre

func _on_ready() -> void:
    # Tu código de inicialización aquí
    pass

func _handle_movement(delta: float) -> void:
    # Tu lógica de movimiento aquí
    # Ejemplo básico: perseguir al jugador
    if player_chase and is_on_floor():
        var direction = sign(player.position.x - position.x)
        velocity.x = direction * speed
        if animated_sprite:
            animated_sprite.flip_h = direction > 0
    else:
        velocity.x = 0

func _handle_animation() -> void:
    # Tu lógica de animaciones aquí
    if not animated_sprite:
        return
    
    if abs(velocity.x) > 0:
        animated_sprite.play("walk")
    else:
        animated_sprite.play("idle")
```

---

## 🎯 Variables Heredables de EnemyBase

### Variables @export (Configurables en Inspector)

| Variable | Tipo | Descripción | Valor por Defecto |
|----------|------|-------------|-------------------|
| `speed` | float | Velocidad de movimiento | 100 |
| `max_health` | int | Salud máxima | 100 |
| `damage_to_player` | int | Daño que hace al jugador | 20 |
| `damage_from_attack` | int | Daño que RECIBE del jugador | 25 |
| `coin_reward` | int | Monedas al morir | 20 |
| `knockback_strength` | float | Fuerza del retroceso | 200.0 |
| `knockback_duration` | float | Duración del retroceso | 0.3 |
| `can_enemy_jump` | bool | Puede saltar | false |
| `jump_velocity` | float | Fuerza del salto | -300.0 |
| `jump_height_min` | float | Altura mínima para saltar | 10.0 |
| `jump_height_max` | float | Altura máxima (2 tiles) | 48.0 |
| `jump_horizontal_max` | float | Distancia horizontal máxima | 150.0 |
| `jump_cooldown` | float | Tiempo entre saltos | 0.5 |

### Variables Internas (Automáticas)

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `health` | int | Salud actual |
| `player` | Node2D | Referencia al jugador |
| `player_chase` | bool | Si está persiguiendo al jugador |
| `player_in_attack_zone` | bool | Si el jugador está en zona de ataque |
| `can_take_damage` | bool | Si puede recibir daño (cooldown) |
| `is_taking_knockback` | bool | Si está en retroceso |
| `can_jump` | bool | Si puede saltar (cooldown) |
| `jump_timer` | float | Timer del salto |

---

## 🔧 Funciones Heredables

### Funciones Virtuales (Override en clases hijas)

```gdscript
func _on_ready() -> void:
    # Inicialización del enemigo específico
    pass

func _handle_movement(delta: float) -> void:
    # Lógica de movimiento personalizada
    pass

func _handle_animation() -> void:
    # Lógica de animaciones personalizada
    pass

func _on_take_damage(damage_amount: int, is_attack: bool) -> void:
    # Reacción personalizada al recibir daño
    pass

func _on_death() -> void:
    # Comportamiento al morir (ya implementado, pero override posible)
    pass

func _on_player_detected(body: Node2D) -> void:
    # Cuando detecta al jugador
    pass

func _on_player_lost(body: Node2D) -> void:
    # Cuando pierde al jugador
    pass

func _on_attack_zone_entered(body: Node2D) -> void:
    # Cuando el jugador entra en zona de ataque
    pass

func _on_attack_zone_exited(body: Node2D) -> void:
    # Cuando el jugador sale de zona de ataque
    pass
```

### Funciones de Utilidad (Listas para usar)

```gdscript
# Sistema de salto
should_jump_to_reach_player() -> bool
    # Verifica si debe saltar para alcanzar al jugador

perform_jump() -> void
    # Ejecuta el salto

# Sistema de daño
take_damage(damage_amount: int, is_attack: bool = false) -> void
    # Recibe daño (ya implementado, llamar con super si override)

apply_knockback() -> void
    # Aplica retroceso (automático al recibir daño)

# Utilidades
get_damage_to_player() -> int
    # Retorna el daño que hace al jugador

enemy() -> void
    # Identificador (para has_method("enemy"))
```

---

## 📝 Checklist para Crear un Nuevo Enemigo

### En el Editor de Godot:

- [ ] Crear escena con CharacterBody2D como raíz
- [ ] Configurar `collision_layer = 4` y `collision_mask = 1`
- [ ] Agregar AnimatedSprite2D con animaciones (mínimo: idle, walk)
- [ ] Agregar CollisionShape2D para el cuerpo
- [ ] Crear `detection_area` (Area2D):
  - [ ] `collision_layer = 0`, `collision_mask = 4`
  - [ ] `monitorable = false`
  - [ ] Agregar CollisionShape2D (normalmente CircleShape2D grande)
  - [ ] Conectar señales `body_entered` y `body_exited`
- [ ] Crear `enemy_hitbox` (Area2D):
  - [ ] `collision_layer = 8`, `collision_mask = 4`
  - [ ] Agregar CollisionShape2D (similar al cuerpo)
  - [ ] Conectar señales `body_entered` y `body_exited`
- [ ] Agregar Timer `take_damage_cooldown`:
  - [ ] `wait_time = 0.5`, `one_shot = true`
  - [ ] Conectar señal `timeout`
- [ ] (Opcional) Agregar ProgressBar `health_bar`
- [ ] Adjuntar script que extienda de `EnemyBase`

### En el Script:

- [ ] `extends EnemyBase`
- [ ] Implementar `_ready()` con configuración
- [ ] Llamar `super._ready()` al final de `_ready()`
- [ ] Implementar `_handle_movement(delta)` si es necesario
- [ ] Implementar `_handle_animation()` si es necesario
- [ ] (Opcional) Override otras funciones virtuales

---

## 🚨 Errores Comunes

### ❌ El enemigo no recibe daño
**Causa:** Señal `timeout` del timer no conectada
**Solución:** Conectar `take_damage_cooldown.timeout` → `_on_take_damage_cooldown_timeout`

### ❌ El enemigo no detecta al jugador
**Causa:** `collision_mask` incorrecto en `detection_area`
**Solución:** Verificar que `collision_mask = 4` (Layer 3 del jugador, valor 4)

### ❌ El jugador no recibe daño del enemigo
**Causa:** `collision_mask` incorrecto en `enemy_hitbox`
**Solución:** Verificar que `collision_mask = 4` y `collision_layer = 8`

### ❌ Los enemigos se bloquean entre sí
**Causa:** `collision_mask` del CharacterBody2D incluye layer 4
**Solución:** `collision_mask = 1` (solo terreno)

### ❌ El enemigo atraviesa el terreno
**Causa:** `collision_mask` no incluye layer 1
**Solución:** `collision_mask = 1`

### ❌ El enemigo no hace knockback
**Causa:** Variable `player` es null
**Solución:** Verificar que `detection_area` detecte correctamente al jugador

---

## 📚 Ejemplos de Referencia

### Ejemplo Básico: Slime
Ver: `scripts/enemies/enemy.gd` y `scenes/charactes/enemies/enemy.tscn`

### Ejemplo Avanzado: Jabalí con Carga
Ver: `scripts/enemies/jabali_carga.gd` y `scenes/charactes/enemies/jabali_carga.tscn`
- Incluye estados (IDLE, WALK, RUN, PREPARE, ATTACK, COOLDOWN, JUMP)
- Sistema de carga con preparación
- Salto habilitado
- Velocidades variables por estado

---

## 🎨 Recomendaciones de Diseño

1. **Tamaño de detection_area:** 200-300 píxeles de radio para enemigos normales
2. **Tamaño de enemy_hitbox:** Ligeramente más grande que el CollisionShape2D del cuerpo
3. **Velocidad estándar:** 80-120 para enemigos lentos, 150-200 para rápidos
4. **Salud estándar:** 50-100 para enemigos básicos, 150+ para mini-bosses
5. **Feedback visual:** Usar `animated_sprite.modulate` para mostrar daño (implementado en EnemyBase)

---

## 🔗 Más Información

- Clase base: `scripts/enemies/enemy_father.gd` (EnemyBase)
- Sistema de jugador: `scripts/player/player.gd`
- Variable global de ataque: `Global.player_current_attack`

---

**✨ ¡Listo! Con esta guía deberías poder crear enemigos sin problemas.**

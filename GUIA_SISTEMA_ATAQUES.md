# 🎮 Sistema de Ataques - Guía de Uso

## 📋 Resumen

El sistema de ataques está completamente integrado y funciona con el formato:
```gdscript
{
    "type": "attack",
    "player": "NombreJugador",
    "damage": 10
}
```

## ⚔️ Cómo Enviar Ataques

### Opción 1: Enviar ataque manualmente
```gdscript
# En cualquier script
Network.send_attack(10)  # Envía ataque con 10 de daño
```

### Opción 2: Sistema automático (cada 5 enemigos muertos)
```gdscript
# En el script del jugador cuando mata un enemigo
func _on_enemy_killed(_coin_reward: int):
    enemies_killed_this_run += 1
    
    # Notificar a Network
    if has_node("/root/Network"):
        Network.enemy_killed()
```

Esto automáticamente:
- Cuenta los enemigos muertos
- Envía un ataque cuando llegas a 5
- Resetea el contador
- Muestra prints en consola

## 📨 Cómo Recibir Ataques

### En tu script de nivel:

```gdscript
extends Node2D

func _ready():
    # Conectar a la señal de ataques
    if has_node("/root/Network"):
        var network = get_node("/root/Network")
        if network.has_signal("ataque_recibido"):
            network.ataque_recibido.connect(_on_ataque_recibido)
            print("✅ Conectado a señal de ataques")

func _on_ataque_recibido(attack_data: Dictionary):
    var attacker = attack_data.get("player", "desconocido")
    var damage = attack_data.get("damage", 10)
    
    print("💥 ¡Ataque recibido de ", attacker, "!")
    print("💥 Daño: ", damage)
    
    # Aplicar el ataque al jugador
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("take_damage"):
        player.take_damage(damage)
```

## 📊 Prints en Consola

### Cuando matas enemigos:
```
💀 [NETWORK] Enemigos muertos: 1/5
💀 [NETWORK] Enemigos muertos: 2/5
💀 [NETWORK] Enemigos muertos: 3/5
💀 [NETWORK] Enemigos muertos: 4/5
💀 [NETWORK] Enemigos muertos: 5/5
⚔️ [NETWORK] ¡5 ENEMIGOS MUERTOS! Enviando ataque...
⚔️ [ATTACK] Enviando ataque: {type: attack, player: Angel, damage: 10}
```

### Cuando recibes un ataque:
```
⚔️ [NETWORK] ¡ATAQUE RECIBIDO!
⚔️ [NETWORK] Jugador: AmigO
⚔️ [NETWORK] Daño: 10
⚔️ [NETWORK] Datos completos: {type: attack, player: AmigO, damage: 10}
```

## 🔧 Funciones Disponibles

### Network.send_attack(damage: int = 10)
Envía un ataque inmediatamente
```gdscript
Network.send_attack()      # Daño por defecto (10)
Network.send_attack(25)    # Daño personalizado
```

### Network.enemy_killed()
Incrementa contador y envía ataque automático al llegar a 5
```gdscript
Network.enemy_killed()
```

### Network.send_game_data(payload: Dictionary)
Envía cualquier dato de juego
```gdscript
Network.send_game_data({
    "type": "attack",
    "player": "Angel",
    "damage": 15
})
```

## 🎯 Señales Disponibles

### ataque_recibido(data: Dictionary)
Se emite cuando recibes un ataque del oponente
```gdscript
Network.ataque_recibido.connect(_on_attack)
```

### game_message_received(data: Dictionary)
Se emite para TODOS los mensajes de juego (incluye ataques)
```gdscript
Network.game_message_received.connect(_on_game_message)
```

## 📦 Estructura del Mensaje

### Al enviar:
```json
{
    "event": "send-game-data",
    "data": {
        "matchId": "123abc",
        "payload": {
            "type": "attack",
            "player": "Angel",
            "damage": 10
        }
    }
}
```

### Al recibir:
```json
{
    "event": "receive-game-data",
    "data": {
        "payload": {
            "type": "attack",
            "player": "AmigO",
            "damage": 10
        }
    }
}
```

## 🚀 Ejemplo Completo

```gdscript
# nivel.gd
extends Node2D

@onready var player = $player

func _ready():
    # Conectar señales
    if has_node("/root/Network"):
        var network = get_node("/root/Network")
        network.ataque_recibido.connect(_on_ataque_recibido)
    
    # Conectar muerte de enemigos del jugador
    if player:
        player.connect("enemy_killed", _on_player_killed_enemy)

func _on_player_killed_enemy():
    # Notificar a Network (envía ataque cada 5 enemigos)
    Network.enemy_killed()

func _on_ataque_recibido(attack_data: Dictionary):
    var damage = attack_data.get("damage", 10)
    var attacker = attack_data.get("player", "desconocido")
    
    print("💥 ¡", attacker, " te atacó con ", damage, " de daño!")
    
    # Aplicar daño al jugador
    if player and player.has_method("take_damage"):
        player.take_damage(damage)
    
    # Spawnear enemigos extra (opcional)
    _spawn_extra_enemies(2)

func _spawn_extra_enemies(count: int):
    # Tu lógica para spawnear enemigos
    pass
```

## ✅ Checklist

- [x] Sistema detecta `"type": "attack"` correctamente
- [x] Señal `ataque_recibido` emitida cuando llega ataque
- [x] Función `send_attack()` para enviar ataques
- [x] Función `enemy_killed()` para sistema automático
- [x] Contador de enemigos (cada 5 envía ataque)
- [x] Prints de debug en consola
- [ ] Conectar señales en tu nivel
- [ ] Implementar efectos al recibir ataque

## 🐛 Debug

Si no recibes ataques:
1. Verifica que estés en una partida: `print(Network.match_id)`
2. Verifica la conexión: `print(Network.ws.get_ready_state())` (debe ser 1)
3. Revisa los prints en consola
4. Verifica que conectaste la señal `ataque_recibido`

Si no envías ataques:
1. Verifica que llamas `Network.enemy_killed()` al matar enemigos
2. Verifica que `match_id` no esté vacío
3. Revisa los prints de envío en consola

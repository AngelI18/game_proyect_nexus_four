# Sistema Multijugador - Guía de Funcionamiento

## 📋 Resumen del Sistema

El sistema multijugador funciona a través de WebSockets con el servidor UCN. Los jugadores se envían **ataques** y **señales de derrota** entre sí, sin usar el evento `finish-game` del servidor.

---

## 🎮 Flujo de Juego

### 1. **Envío de Ataques**
- Cada 5 enemigos muertos (con sistema de puntos ponderado por dificultad)
- Se envía mediante `send-game-data` con payload: `{"type": "attack", "player": nombre, "damage": 10}`
- El oponente recibe el ataque en el evento `receive-game-data`

### 2. **Recepción de Ataques**
- Se detecta en `MatchManager` cuando llega `{"type": "attack"}`
- Se emite la señal `ataque_recibido(data: Dictionary)`
- **El nivel debe instanciar el castigo** (spawn enemigos, debuff, etc.)

**Ejemplo de implementación en tu nivel:**
```gdscript
func _ready():
    if has_node("/root/Network"):
        var network = get_node("/root/Network")
        network.ataque_recibido.connect(_on_ataque_recibido)

func _on_ataque_recibido(attack_data: Dictionary):
    var damage = attack_data.get("damage", 10)
    print("💥 ¡Recibiste un ataque! Daño:", damage)
    
    # Aquí implementa tu castigo:
    # - Spawnear enemigos extra
    # - Aplicar debuff al jugador
    # - Efectos visuales/sonoros
    # - etc.
    _spawn_punishment_enemies(3)
```

### 3. **Envío de Derrota (Muerte del Jugador)**
- Cuando el jugador muere o abandona, se llama `Network.notify_player_died()`
- Esto envía `{"type": "defeat"}` al oponente
- **NO abandona la match** ni **desmarca disponibilidad** automáticamente

### 4. **Recepción de Derrota del Oponente (Victoria)**
- Cuando llega `{"type": "defeat"}`, se emite `match_ended("VICTORY", "opponent_surrendered")`
- Se muestra el popup de victoria
- Cuando el popup desaparece (2.5s), **el jugador se marca como disponible automáticamente**

### 5. **Desconexión del Oponente**
- El servidor envía `close-match`
- Se emite `match_ended("VICTORY", "opponent_disconnected")`
- Misma lógica de victoria que arriba

---

## ⏸️ Menú de Pausa

### Comportamiento
- **Siempre pausa el juego** (tanto singleplayer como multiplayer)
- Deshabilita el botón "Reiniciar" en multiplayer
- Oculta el HUD cuando está abierto

### Al Salir del Menú de Pausa en Multiplayer
1. Envía `notify_player_died()` (señal de derrota)
2. Espera 0.3 segundos
3. Vuelve al menú principal
4. **NO desmarca disponibilidad** (el jugador sigue "ocupado" hasta que se cierre el resultado)

---

## 🏁 Gestión de Disponibilidad del Jugador

El jugador se marca como **disponible** en estos escenarios:

### ✅ Escenario 1: Victoria/Derrota Natural
- El popup `MatchResultPopup` se muestra durante 2.5 segundos
- Al desaparecer, llama `Network.set_player_available()`
- El jugador queda disponible en el lobby

### ✅ Escenario 2: Muerte y Vuelta al Lobby
- `death_scene.gd` llama `Network.notify_player_died()` al aparecer
- Al presionar "Menu Principal":
  1. Llama `Network.leave_match()`
  2. Espera 0.3s
  3. Llama `Network.set_player_available()`
  4. Cambia a la escena del lobby

### ✅ Escenario 3: Salir desde el Menú de Pausa
- Similar al escenario 2, pero sin marcar disponibilidad
- El jugador debe volver manualmente al lobby para marcarse disponible

---

## 🔧 Funciones Clave

### Network.gd
```gdscript
# Enviar ataque (automático cada 5 enemigos)
Network.send_attack(damage: int = 10)

# Enviar señal de derrota (NO desmarca disponibilidad)
Network.notify_player_died()

# Salir de la match (envía quit-match al servidor)
Network.leave_match()

# Marcar jugador como disponible en el lobby
Network.set_player_available()
```

### MatchManager.gd
```gdscript
# Enviar datos personalizados al oponente
match_manager.send_game_data({"type": "attack", ...})

# Señales que puedes escuchar:
match_manager.match_ended.connect(func(result, reason): ...)
match_manager.attack_received.connect(func(data): ...)
match_manager.opponent_left.connect(func(): ...)
```

---

## ⚠️ Puntos Importantes

1. **NO uses `finish-game`** - La victoria solo se otorga cuando el oponente envía `{"type": "defeat"}`
2. **Los castigos NO se instancian automáticamente** - Debes implementarlos en tu nivel
3. **La disponibilidad NO se maneja automáticamente** - Debes llamar `set_player_available()` manualmente
4. **El pause menu SIEMPRE pausa** - Tanto en single como en multiplayer
5. **Los ataques son unidireccionales** - Envías cuando matas 5 enemigos, no hay confirmación

---

## 📊 Sistema de Puntos para Ataques

Los enemigos otorgan puntos según su dificultad:
- **Enemigos fáciles (< 4 golpes)**: 1 punto
- **Enemigos difíciles (≥ 4 golpes)**: 2 puntos

Cuando acumulas **5 puntos**, se envía un ataque automáticamente.

```gdscript
# En player.gd
func _on_enemy_killed(_coin_reward: int, hits_received: int):
    var points = 1 if hits_received < 4 else 2
    Network.add_enemy_points(points)  # Auto-envía ataque al llegar a 5
```

---

## 🧪 Testing

Para probar el sistema sin multijugador real:
```gdscript
# En tu nivel, simula un ataque recibido:
Input.is_action_just_pressed("test_attack"):
    Network._on_attack_received({
        "type": "attack",
        "player": "TestPlayer",
        "damage": 10
    })
```

---

## 📝 Checklist de Implementación en Niveles

- [ ] Conectar señal `Network.ataque_recibido` en `_ready()`
- [ ] Implementar función `_on_ataque_recibido(attack_data)`
- [ ] Crear sistema de castigos (spawn enemigos, debuffs, etc.)
- [ ] Añadir efectos visuales/sonoros para ataques recibidos
- [ ] Testear con Input simulado antes de probar online
- [ ] Verificar que el HUD esté en el grupo "hud"
- [ ] Asegurar que el jugador emite `enemy_died` con `hits_received`

---

## 🐛 Troubleshooting

**El oponente no recibe mis ataques:**
- Verifica que `Network.match_id != ""`
- Revisa que el contador de puntos llegue a 5
- Confirma que los enemigos emiten `enemy_died(coin_reward, hits_received)`

**No recibo ataques del oponente:**
- Asegúrate de conectar la señal `ataque_recibido` en tu nivel
- Verifica que `MatchManager` detecta `"type": "attack"`
- Revisa los logs: `⚔️ [NETWORK] ¡ATAQUE RECIBIDO!`

**El jugador no se marca disponible:**
- Verifica que el popup `MatchResultPopup` llame `set_player_available()`
- En death_scene, confirma que se llama antes de cambiar escena
- Revisa logs: `✅ [NETWORK] Jugador marcado como disponible`

**El pause menu no funciona:**
- Asegúrate que el HUD esté en el grupo "hud"
- Verifica que `btn_reiniciar` existe en el nodo Panel
- Revisa que `toggle_pausa()` se llama correctamente

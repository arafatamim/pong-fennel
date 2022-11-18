(var vec2 (require :batteries.vec2))
(var mathx (require :batteries.mathx))

(var (SCREEN_W SCREEN_H _) (love.window.getMode))

;; CONSTANTS
(var PADDLE_W 15)
(var PADDLE_H 100)
;; =========

(var player1 {:pos (vec2 0 (/ SCREEN_H 2.5)) :lives 3})
(var player2 {:pos (vec2 (- SCREEN_W PADDLE_W) (/ SCREEN_H 2))
              :lives 3})

(var ball {:pos (vec2 0 0) :vel (vec2 4 4) :size 15})
(fn ball.bounce [self x y]
  (set self.vel.x (* x self.vel.x))
  (set self.vel.y (* y self.vel.y)))

(fn ball.reset [self]
  (set self.pos (vec2 (/ SCREEN_W 2) (/ SCREEN_H 2)))
  (set self.vel (vec2 (* 4 (mathx.random_sign)) (* 4 (mathx.random_sign)))))

(var winner -1)

(fn game-reset []
  (set player1.lives 3)
  (set player2.lives 3)
  (ball:reset)
  (set winner -1))

(fn new-soundwave [freq samplerate duration]
 (local duration (or duration (/ 1 freq)))
 (local samples (math.floor (* duration samplerate)))
 (local data (love.sound.newSoundData samples))
 (for [i 1 samples]
  (local v (* (- i 1) (/ freq samplerate)))
  (local v (math.sin (* v math.pi 2)))
  (data:setSample i v))
 data)

(local wall-collide-audio (love.audio.newSource (new-soundwave 100 44100 0.1) :static))
(local paddle-collide-audio (love.audio.newSource (new-soundwave 200 44100 0.1) :static))
(local ball-out-audio (love.audio.newSource (new-soundwave 50 44100 0.7) :static))

(fn love.update []
  (when (> winner 0)
    (lua :return))
  ;;
  ;; set ball in motion
  (set ball.pos (ball.pos:vector_add_inplace ball.vel))
  ;;
  ;; ball bounce on wall
  (when (> ball.pos.y (- SCREEN_H ball.size))
    (ball:bounce 1 -1)
    (love.audio.play wall-collide-audio))
  (when (< ball.pos.y 0)
    (ball:bounce 1 -1)
    (love.audio.play wall-collide-audio))
  ;;
  ;; ball runs out of x axis
  (when (>= ball.pos.x (- SCREEN_W ball.size))
    (love.audio.play ball-out-audio)
    (set player2.lives (- player2.lives 1))
    (ball:reset))
  (when (<= ball.pos.x 0)
    (love.audio.play ball-out-audio)
    (set player1.lives (- player1.lives 1))
    (ball:reset))
  ;;
  ;; decide game winner
  (when (<= player1.lives 0)
    (set winner 2))
  (when (<= player2.lives 0)
    (set winner 1))
  ;;
  ;; ball bounce on paddles
  (when (and (< ball.pos.x (+ player1.pos.x 5))
             (<= ball.pos.y (+ player1.pos.y PADDLE_H))
             (>= ball.pos.y (- player1.pos.y ball.size)))
    (ball:bounce -1 1)
    (love.audio.play paddle-collide-audio)
    (set ball.pos.x (+ ball.pos.x 10)))
  ;;
  (when (and (> ball.pos.x (- player2.pos.x ball.size))
             (<= ball.pos.y (+ player2.pos.y PADDLE_H))
             (>= ball.pos.y (- player2.pos.y ball.size)))
    (ball:bounce -1 1)
    (love.audio.play paddle-collide-audio)
    (set ball.pos.x (- ball.pos.x 10)))
  ;;
  ;;
  (when (love.keyboard.isDown :s)
    (player1.pos:vector_add_inplace (vec2 0 10)))
  (when (love.keyboard.isDown :w)
    (player1.pos:vector_add_inplace (vec2 0 -10)))
  (when (love.keyboard.isDown :down)
    (player2.pos:vector_add_inplace (vec2 0 10)))
  (when (love.keyboard.isDown :up)
    (player2.pos:vector_add_inplace (vec2 0 -10)))
  ;;
  ;; keep paddles in view
  (when (< player1.pos.y 0)
    (set player1.pos.y 0))
  (when (> player1.pos.y (- SCREEN_H PADDLE_H))
    (set player1.pos.y (- SCREEN_H PADDLE_H)))
  (when (< player2.pos.y 0)
    (set player2.pos.y 0))
  (when (> player2.pos.y (- SCREEN_H PADDLE_H))
    (set player2.pos.y (- SCREEN_H PADDLE_H))))

(local font (love.graphics.newFont 26))
(love.graphics.setFont font)

(fn love.draw []
  (when (> winner 0)
    (love.graphics.print (.. "PLAYER " winner " WINS") 0 0)
    (love.graphics.print (.. "PRESS F2 TO START NEW GAME") 0 30)
    (lua :return))
  (love.graphics.setColor 255 255 255 1)
  (love.graphics.rectangle :fill player1.pos.x player1.pos.y PADDLE_W PADDLE_H
                           10 5 10)
  (love.graphics.rectangle :fill player2.pos.x player2.pos.y PADDLE_W PADDLE_H
                           10 5 10)
  (love.graphics.rectangle :fill ball.pos.x ball.pos.y ball.size ball.size 10
                           10 5)
  ;; player 1 lives
  (love.graphics.push)
  (love.graphics.translate 10 10)
  (love.graphics.scale 2)
  (for [_ 1 player1.lives 1]
    (love.graphics.translate 15 0)
    (love.graphics.push)
    (love.graphics.rotate 3.14)
    (love.graphics.polygon :fill 0 0 2 2 4 2 6 0 6 -2 0 -8 -6 -2 -6 0 -4 2 -2 2)
    (love.graphics.pop))
  (love.graphics.pop)
  ;; player 2 lives
  (love.graphics.push)
  (love.graphics.translate (- SCREEN_W 135) 10)
  (love.graphics.scale 2)
  (for [_ 1 player2.lives 1]
    (love.graphics.translate 15 0)
    (love.graphics.push)
    (love.graphics.rotate 3.14)
    (love.graphics.polygon :fill 0 0 2 2 4 2 6 0 6 -2 0 -8 -6 -2 -6 0 -4 2 -2 2)
    (love.graphics.pop))
  (love.graphics.pop))

(fn love.keypressed [key]
  (match key
    :f2 (game-reset)
    :q (os.exit)
    :escape (os.exit)))

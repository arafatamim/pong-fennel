all: transpile compile

transpile:
	fennel --globals love \
		--compile main.fnl \
		> main.lua

compile: transpile
	zip -r pong-fennel.love batteries/ main.lua

run: transpile
	love .

js: transpile compile
	love.js pong-fennel.love pong-fennel -c -t Pong

build: clean
	mkdir -p .build
	erlc -o .build/ *.erl

exp4: build
	cd .build && erl -eval 'paxy:start([2000, 2000, 2000, 2000, 2000])'

ft: build
	cd .build && erl -eval 'paxy:start([10000, 9000, 10000, 10000, 10000])'

clean:
	rm -rf .build
	rm -f *.beam

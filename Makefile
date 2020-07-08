.PHONY: test clean

venv: venv/bin/activate

venv/bin/activate: requirements.txt
	test -d venv || virtualenv venv
	. venv/bin/activate; pip install -Ur requirements.txt
	touch venv/bin/activate

test:
	python -m unittest

function:
	rm -rf venv/lib/python3.8/site-packages/pip*
	rm -rf venv/lib/python3.8/site-packages/pkg_resources*
	rm -rf venv/lib/python3.8/site-packages/setuptools*
	rm -rf venv/lib/python3.8/site-packages/Cryptodome/SelfTest
	zip -r9 function.zip lambda.py

clean:
	rm -rf venv
	rm -f function.zip

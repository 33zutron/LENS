class A {
    void foo() {
	// == used to have the wrong precedence in tree-sitter-java
	// which prevented lens to match such code with $X == $X
	return a+b == a+b;
    }
}

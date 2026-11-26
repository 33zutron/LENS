// https://github.com/returntocorp/lens/issues/4150
class Test {
    boolean f() {
        int x = 0;
        synchronized (this) {
            x++;
        }
        //OK:
        return x == 0;
    }
}

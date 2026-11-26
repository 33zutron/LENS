/* https://github.com/returntocorp/lens/issues/3727 */
int main() {
    int x = 3;
    int y = 5;
    /* ruleid: c-comparing-const-vars */
    if (x < y) {
        print("less");
    }
}


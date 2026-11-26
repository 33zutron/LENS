// https://github.com/returntocorp/lens/issues/5590
public class TypedEnumerationExample{
    public void bad(){
        for (StackTraceElement ste : Thread.currentThread().getStackTrace()) {
            // ruleid: java-iterator-missed-propagation
            System.out.println(ste);
        }
    }
}

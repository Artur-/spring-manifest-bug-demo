import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

public class TestApp {

    public static void main(String[] args) throws Exception {
        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();

        Resource[] emptyRoot = resolver.getResources("classpath*:**/*.class");
        Resource[] withPrefix = resolver.getResources("classpath*:org/**/*.class");

        System.out.println("Pattern: classpath*:**/*.class");
        System.out.println("Found: " + emptyRoot.length + " resources");
        System.out.println();
        System.out.println("Pattern: classpath*:org/**/*.class");
        System.out.println("Found: " + withPrefix.length + " resources");
        System.out.println();

        if (Math.abs(withPrefix.length - emptyRoot.length) > 10) {
            System.out.println("FAILED: The numbers should be similar but they are not.");
            System.out.println("The empty root pattern is not finding resources from manifest Class-Path entries.");
            System.exit(1);
        } else {
            System.out.println("OK: Both patterns found similar numbers of resources.");
            System.exit(0);
        }
    }
}

import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

/**
 * Minimal test application to demonstrate the bug in Spring Framework's
 * PathMatchingResourcePatternResolver when using absolute paths in JAR
 * manifest Class-Path entries.
 *
 * This simulates the behavior seen on Windows with Gradle when the classpath
 * is too long and Gradle creates a classpath JAR with absolute paths.
 */
public class TestApp {

    public static void main(String[] args) throws Exception {
        System.out.println("=".repeat(70));
        System.out.println("Testing PathMatchingResourcePatternResolver with Manifest Classpath");
        System.out.println("=".repeat(70));
        System.out.println();

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();

        // Test 1: Scanning from root with wildcards (FAILS with absolute paths in manifest)
        System.out.println("TEST 1: Scanning with empty root");
        System.out.println("Pattern: classpath*:**/*.class");
        System.out.println("-".repeat(70));

        Resource[] resources1 = resolver.getResources("classpath*:**/*.class");
        System.out.println("Found: " + resources1.length + " classes");

        if (resources1.length < 100) {
            System.out.println("❌ BUG DETECTED: Too few resources found!");
            System.out.println("   This indicates that JARs from the manifest are being rejected.");
        } else {
            System.out.println("✓ OK: Found expected number of resources");
        }

        System.out.println();
        System.out.println("Sample resources found:");
        for (int i = 0; i < Math.min(5, resources1.length); i++) {
            System.out.println("  - " + resources1[i].getURL());
        }

        System.out.println();
        System.out.println("=".repeat(70));
        System.out.println();

        // Test 2: Scanning with a package prefix (WORKS even with absolute paths)
        System.out.println("TEST 2: Scanning with package prefix");
        System.out.println("Pattern: classpath*:org/**/*.class");
        System.out.println("-".repeat(70));

        Resource[] resources2 = resolver.getResources("classpath*:org/**/*.class");
        System.out.println("Found: " + resources2.length + " classes");

        if (resources2.length > 100) {
            System.out.println("✓ OK: Package prefix pattern works correctly");
            System.out.println("   This confirms that the issue is specific to empty-root patterns.");
        } else {
            System.out.println("⚠ Unexpected: Even package prefix pattern found few resources");
        }

        System.out.println();
        System.out.println("Sample resources found:");
        for (int i = 0; i < Math.min(5, resources2.length); i++) {
            System.out.println("  - " + resources2[i].getURL());
        }

        System.out.println();
        System.out.println("=".repeat(70));
        System.out.println();

        // Summary
        System.out.println("SUMMARY:");
        System.out.println("-".repeat(70));
        System.out.println("Empty root pattern (classpath*:**/*.class): " + resources1.length + " resources");
        System.out.println("Package prefix pattern (classpath*:org/**/*.class): " + resources2.length + " resources");
        System.out.println();

        if (resources1.length < 100 && resources2.length > 100) {
            System.out.println("BUG CONFIRMED!");
            System.out.println("The PathMatchingResourcePatternResolver is rejecting absolute paths");
            System.out.println("in the JAR manifest Class-Path entries.");
            System.out.println();
            System.out.println("Root cause: PathMatchingResourcePatternResolver.java:615");
            System.out.println("The security check 'candidate.getCanonicalPath().contains(parent.getCanonicalPath())'");
            System.out.println("fails for absolute paths in the manifest.");
            System.exit(1);
        } else {
            System.out.println("No bug detected - both patterns found similar resource counts.");
            System.out.println("This might mean the classpath JAR doesn't have absolute paths,");
            System.out.println("or the issue doesn't reproduce in this environment.");
            System.exit(0);
        }
    }
}

# Bait for java-reviewer

Copy `OrderReport.java.txt` to `orders-service/src/main/java/com/example/orders/OrderReport.java` in the sample project, commit it on a branch and run `/java-developer:review`. The review must find the N+1 (repository call in a loop) and PII logging (customer email).

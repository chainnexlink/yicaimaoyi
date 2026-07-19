-- Flyway 10 inspects this Performance Schema view when connecting to MySQL 8.4.
-- Keep the application account least-privileged outside its own database.
GRANT SELECT ON performance_schema.user_variables_by_thread TO 'yicai_app'@'%';
FLUSH PRIVILEGES;

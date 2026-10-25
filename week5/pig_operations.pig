-- ==========================================================
-- Apache Pig Latin Script Demonstrating:
-- 1. LOAD & PROJECT (FOREACH ... GENERATE)
-- 2. FILTER
-- 3. GROUP (GROUP BY and AGGREGATE)
-- 4. JOIN
-- 5. SORT (ORDER BY)
-- ==========================================================

-- 1. Load Employees Data: (id, name, department, salary)
employees = LOAD '$EMP_INPUT' USING PigStorage(',') 
    AS (emp_id:int, name:chararray, dept_id:chararray, salary:int);

-- 2. Load Departments Data: (dept_id, dept_name)
departments = LOAD '$DEPT_INPUT' USING PigStorage(',') 
    AS (dept_id:chararray, dept_name:chararray);

-- ==========================================================
-- OPERATION 1: PROJECT (Select specific columns)
-- ==========================================================
projected_data = FOREACH employees GENERATE name, salary;

-- ==========================================================
-- OPERATION 2: FILTER (Employees with salary >= 60000)
-- ==========================================================
filtered_data = FILTER employees BY salary >= 60000;

-- ==========================================================
-- OPERATION 3: GROUP (Group by department & compute stats)
-- ==========================================================
grouped_by_dept = GROUP employees BY dept_id;
dept_stats = FOREACH grouped_by_dept GENERATE 
    group AS dept_id, 
    COUNT(employees) AS emp_count, 
    AVG(employees.salary) AS avg_salary;

-- ==========================================================
-- OPERATION 4: JOIN (Join employees with department names)
-- ==========================================================
joined_data = JOIN employees BY dept_id, departments BY dept_id;
joined_projected = FOREACH joined_data GENERATE 
    employees::emp_id AS id, 
    employees::name AS name, 
    departments::dept_name AS department, 
    employees::salary AS salary;

-- ==========================================================
-- OPERATION 5: SORT (Sort joined data by salary DESCENDING)
-- ==========================================================
sorted_data = ORDER joined_projected BY salary DESC;

-- Store Results into Output Folders
rmf $OUTPUT_DIR/projected
rmf $OUTPUT_DIR/filtered
rmf $OUTPUT_DIR/grouped
rmf $OUTPUT_DIR/joined
rmf $OUTPUT_DIR/sorted

STORE projected_data INTO '$OUTPUT_DIR/projected' USING PigStorage(',');
STORE filtered_data INTO '$OUTPUT_DIR/filtered' USING PigStorage(',');
STORE dept_stats INTO '$OUTPUT_DIR/grouped' USING PigStorage(',');
STORE joined_projected INTO '$OUTPUT_DIR/joined' USING PigStorage(',');
STORE sorted_data INTO '$OUTPUT_DIR/sorted' USING PigStorage(',');

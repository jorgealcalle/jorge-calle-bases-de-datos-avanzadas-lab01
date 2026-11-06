
-- Consulta tablas de HR--
SELECT table_name
FROM user_tables
ORDER BY table_name;

-- consulta del id y nombre en la tabla departamento
SELECT department_id, department_name FROM departments;

-- consulta información en tabla de empleados y departamentos--
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.email,
    e.salary,
    d.department_id,
    d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id;

--  Ejecutar la consulta SQL/XML--

SELECT 
    XMLELEMENT("Department",
        XMLATTRIBUTES(d.department_id AS "DeptId"),
        XMLFOREST(d.department_name AS "DepartmentName"),
        XMLELEMENT("Employees",
            XMLAGG(
                XMLELEMENT("Employee",
                    XMLATTRIBUTES(e.employee_id AS "EmpId"),
                    XMLFOREST(
                        e.first_name AS "FirstName",
                        e.last_name AS "LastName",
                        e.salary AS "Salary"
                    )
                )
            )
        )
    ) AS xml_result
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name;

--   Crear la tabla vinculada al Esquema XML

CREATE TABLE validated_departments OF XMLType
  XMLSCHEMA "http://hr.schemas/department_schema.xsd"
  ELEMENT "Departments";
  
  
  
  -- registrar esquema  XML--
  
  BEGIN
  DBMS_XMLSCHEMA.registerSchema(
    schemaurl => 'http://hr.schemas/department_schema.xsd',
    schemadoc => '<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Departments">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Department" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="DepartmentName" type="xs:string"/>
              <xs:element name="Employees">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="Employee" maxOccurs="unbounded">
                      <xs:complexType>
                        <xs:sequence>
                          <xs:element name="FirstName" type="xs:string"/>
                          <xs:element name="LastName" type="xs:string"/>
                          <xs:element name="Salary" type="xs:decimal"/>
                        </xs:sequence>
                        <xs:attribute name="EmpId" type="xs:integer" use="required"/>
                      </xs:complexType>
                    </xs:element>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
            <xs:attribute name="DeptId" type="xs:integer" use="required"/>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>'
  );
END;
/
  -- INSERCIÓN VALIDA----
  INSERT INTO validated_departments VALUES (
  XMLType('
    <Departments>
      <Department DeptId="10">
        <DepartmentName>Administration</DepartmentName>
        <Employees>
          <Employee EmpId="200">
            <FirstName>Jennifer</FirstName>
            <LastName>Whalen</LastName>
            <Salary>4400.00</Salary>
          </Employee>
        </Employees>
      </Department>
    </Departments>
  ')
);
COMMIT;
  
   -- INSERCIÓN NO VALIDA   no está el campo salary----

DECLARE
  v_xml XMLType;
BEGIN
  
  v_xml := XMLType('
    <Departments>
      <Department DeptId="20">
        <DepartmentName>Marketing</DepartmentName>
        <Employees>
          <Employee EmpId="201">
            <FirstName>Michael</FirstName>
            <LastName>Hartstein</LastName>
          </Employee>
        </Employees>
      </Department>
    </Departments>
  ', 'http://hr.schemas/department_schema.xsd');
  
  
  v_xml.schemaValidate();
  
  
  INSERT INTO validated_departments VALUES (v_xml);
  COMMIT;
END;
/
   
   

  
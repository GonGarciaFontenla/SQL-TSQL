/*
Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

create function ej1(@deposito char(2), @producto char(8))
returns varchar(50) as
begin 
declare @cantidad decimal(12,2), @maximo decimal(12,2)
select @cantidad = stoc_cantidad, @maximo = stoc_stock_maximo  from STOCK
where stoc_deposito = @deposito and stoc_producto = @producto
if @cantidad >= @maximo
    return 'DEPOSITO COMPLETO'
return 'Ocupacion del deposito ' + str(@cantidad/@maximo * 100) + '%'
end 
go

/*
2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/
CREATE FUNCTION ej2(@articulo CHAR(8), @fecha DATE)
RETURNS DECIMAL(12,2)
AS 
BEGIN
    DECLARE @cantStock DECIMAL(12,2)
    DECLARE @cantidad DECIMAL(12,2)
    DECLARE @minimo decimal(12,2)
    DECLARE @maximo decimal(12,2)

    DECLARE cStock CURSOR FOR
        SELECT item_cantidad 
        FROM factura 
        join item_factura
        on fact_tipo + fact_sucursal + fact_tipo = item_tipo + item_sucursal + item_numero 
        where item_producto = @articulo and fact_fecha = @fecha

SELECT @cantStock = stoc_cantidad, @minimo = stoc_punto_reposicion, @maximo = stoc_stock_maximo
    FROM stock 
    where stoc_producto = @articulo
    AND stoc_deposito = '00'

OPEN cStock
FETCH NEXT FROM cStock into @cantidad
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cantStock = @cantStock - @cantidad
    if @cantStock < @minimo
        SET @cantStock = @maximo - @minimo
    FETCH NEXT FROM cStock into @cantidad
END 

CLOSE cStock
DEALLOCATE cStock

return @cantStock
END

go

/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.
*/
CREATE PROCEDURE ej3 (@empleadoSinJefe INT OUTPUT) AS 
BEGIN   
DECLARE @gerenteGeneral NUMERIC(6,0)
SELECT @empleadoSinJefe = count(*) 
FROM empleado
WHERE empl_jefe IS NULL
IF @empleadoSinJefe > 1
    SELECT top 1 @gerenteGeneral = empl_codigo from empleado
    WHERE empl_jefe IS NULL
    ORDER BY empl_salario

    UPDATE Empleado SET empl_jefe = @gerenteGeneral
    WHERE empl_jefe is null
    AND empl_codigo <> @gerenteGeneral
END

GO

/*
4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/
CREATE PROCEDURE ej4 (@empMasVendedor numeric(6,0) OUTPUT)
AS
BEGIN 

UPDATE Empleado 
SET empl_comision = (SELECT sum(fact_total) FROM factura where fact_vendedor = Empleado.empl_codigo and year(fact_fecha) = 2012)

SELECT TOP 1 @empMasVendedor = empl_codigo FROM empleado
order by empl_comision

END
GO

/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/
CREATE PROCEDURE ej5 AS
BEGIN
CREATE TABLE Fact_table (
    anio char(4), 
    mes char(2),  
    familia char(3), 
    rubro char(4), 
    zona char(3), 
    cliente char(6),
    producto char(8), 
    cantidad decimal(12,2),
    monto decimal(12,2)
    CONSTRAINT pk_fact_table PRIMARY KEY(anio,mes,familia,rubro,zona,cliente,producto)
)

INSERT INTO Fact_table 
SELECT year(fact_fecha), 
    MONTH(fact_fecha),
    prod_familia,
    prod_rubro,
    depa_zona
    fact_cliente,   
    prod_codigo, 
    SUM(item_cantidad), 
    SUM(item_cantidad * item_precio) 
FROM factura 
join Item_Factura on fact_tipo + fact_sucursal + fact_tipo = item_tipo + item_sucursal + item_numero 
join Producto on item_producto = prod_codigo
join Empleado on fact_vendedor = empl_codigo
join Departamento on empl_departamento = depa_codigo
GROUP BY year(fact_fecha), MONTH(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo

END
go


/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/

CREATE FUNCTION ej11 (@codigo NUMERIC(6,0))
RETURNS INT
AS
BEGIN 
    DECLARE @cantidad INT = 0;
    DECLARE @empSig NUMERIC(6,0);

    DECLARE cursorEmp CURSOR FOR
        SELECT empl_codigo
        FROM empleado
        WHERE empl_jefe = @codigo 
          AND empl_codigo > @codigo;

    SELECT @cantidad = COUNT(*)
    FROM empleado 
    WHERE empl_jefe = @codigo 
      AND empl_codigo > @codigo;

    IF @cantidad = 0
        RETURN 0;

    OPEN cursorEmp;
    FETCH NEXT FROM cursorEmp INTO @empSig;

    WHILE @@FETCH_STATUS = 0
    BEGIN 
        SET @cantidad = @cantidad + dbo.ej11(@empSig);
        FETCH NEXT FROM cursorEmp INTO @empSig;
    END

    CLOSE cursorEmp;
    DEALLOCATE cursorEmp; 

    RETURN @cantidad;
END
GO
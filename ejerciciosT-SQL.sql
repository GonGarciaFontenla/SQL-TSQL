/*
1.✅
2.✅
3.✅
4.✅
5.✅
6.❌
7.✅
8.✅
9.❌ --medio tik muy dificil
10.✅
11.✅
12.✅
13.✅
14.✅
15.✅
16.✅
17.✅
18.✅
19.✅
20.✅
21.✅
22.❌ 
23.✅
24.✅
25.
26.
27.
28.
29.
30.
31.
*/

/*
Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/

GO
create or alter function ej1(@articulo char(8), @deposito char(2))
returns varchar(300) as 
begin 
    declare @ocupacion decimal(12,2), @maximo decimal(12,2)

    select @ocupacion = stoc_Cantidad, @maximo = stoc_stock_maximo from Stock
    where stoc_producto = @articulo and stoc_Deposito = @deposito

    if @ocupacion >= @maximo 
        return 'DEPOSITO COMPLETO'
    return 'OCUPACION DEL DEPOSITO ' + RTRIM(STR(ROUND(@ocupacion * 100.0 / @maximo, 2), 6, 2)) + '%'
end 
GO 


/*
2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/
go
create or alter function ej2(@articulo char(8), @fecha date)
returns decimal(12,2)
as
begin 
    declare 
        @cant_Stock decimal(12,2), 
        @cantidad decimal(12,2), 
        @maximo decimal(12,2), 
        @minimo decimal(12,2)
    declare cStock cursor for 
        select item_Cantidad
        from Item_Factura
        join Factura on fact_tipo + fact_sucursal + fact_tipo = item_tipo + item_sucursal + item_numero 
        where fact_fecha = @fecha and item_producto = @articulo

    select 
        @cant_Stock = stoc_Cantidad, 
        @maximo = stoc_stock_maximo, 
        @minimo = stoc_punto_reposicion
    from stock 
    where stoc_producto = @articulo and stoc_deposito = '00'

    open cStock 
    fetch next from cStock into @Cantidad
    while @@FETCH_STATUS = 0
    begin 
        set  @cant_Stock = @cant_Stock - @cantidad
        if  @cant_Stock < @minimo
            set @cant_Stock = @maximo - @minimo
        FETCH NEXT FROM cStock into @cantidad
    end 

    close cStock
    deallocate cStock

    return @cant_Stock
end
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
create or alter procedure ej3 (@cantSinJefe INT OUTPUT) 
AS
begin 
    declare @gerenteGeneral numeric(6, 0)

    select @cantSinJefe = count(*) 
    from empleado 
    where empl_jefe is null

    if @cantSinJefe > 1 
        select @gerenteGeneral = empl_codigo 
        from Empleado 
        where empl_jefe is null 
        order by empl_salario
    
    update Empleado set empl_jefe = @gerenteGeneral
    where empl_jefe is null 
    and empl_codigo <> @gerenteGeneral
end  
go

/*
4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/
create or alter procedure ej4(@top_vendedor numeric(6,0) output)
as 
begin 
    update Empleado
    set empl_comision = 
        isnull((
        select sum(fact_total) 
        from Factura 
        where fact_vendedor = Empleado.empl_codigo and year(fact_fecha) = 2012
        ),0)

    set @top_vendedor = (select top 1 empl_codigo from Empleado order by empl_comision)
end 
go


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
create or alter procedure ej5
as 
begin
    create table fact_table (
        anio char(4),
        mes char(2),
        familia char(3),
        rubro char(4),
        zona char(3),
        cliente char(6),
        producto char(8),
        cantidad decimal(12,2),
        monto decimal(12,2)
        constraint pk_fact_table primary key(anio,mes,familia,rubro,zona,cliente,producto)
    ) 

    insert into fact_table
    select 
        year(fact_fecha), 
        MONTH(fact_fecha), 
        prod_familia,
        prod_rubro,
        depa_zona, 
        fact_cliente, 
        prod_codigo, 
        sum(item_cantidad),
        sum(item_cantidad*item_precio)
    from Factura
    join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    join Producto on prod_codigo = item_producto
    join Empleado on fact_vendedor = empl_codigo
    join Departamento on depa_codigo = empl_departamento
    group by 
        year(fact_fecha), 
        MONTH(fact_fecha), 
        prod_familia,
        prod_rubro,
        depa_zona, 
        fact_cliente, 
        prod_codigo
end 
go


/*
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/
--drop table VentasEj7
--drop procedure ej7

CREATE TABLE VentasEj7 (
	articulo char(8),
	detalle char(50),
	cant_movimientos int,
	precio decimal(12,2),
	ganancia decimal(12,2)
)
GO 

create procedure ej7(@f1 date, @f2 date)  
as 
begin 
    insert into VentasEj7 
    select 
        prod_codigo,
        prod_detalle, 
        count(item_producto), 
        avg(item_precio), 
        sum(item_cantidad*item_precio)
    from Producto
    join Item_Factura on prod_codigo = item_producto
    join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    where fact_fecha BETWEEN @f1 and @f2
    group by prod_codigo, prod_detalle
end 
go


/*
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:
*/
--drop table diferenciasEj8
go
create function precio_suma_unitaria(@producto char(8))
returns decimal(12,2)
as 
begin 
    declare @sumPrecioUni decimal(12,2)
    declare @componente char(8)
    declare @cantidad decimal(12,2)

    if @producto not in (select comp_producto from Composicion)
    begin
        select @sumPrecioUni = prod_precio from Producto where prod_codigo = @producto
    end
    else
    begin
        set @sumPrecioUni = 0

        declare cComponente cursor for
        select comp_componente, comp_cantidad from Composicion
        where comp_producto = @producto

        open cComponente 
        fetch next from cComponente into @componente, @cantidad
        while @@FETCH_STATUS = 0
        begin
            set @sumPrecioUni = @sumPrecioUni + @cantidad * dbo.precio_suma_unitaria(@componente)
            fetch next from cComponente into @componente, @cantidad 
        end
        close cComponente
        deallocate cComponente
    end

    return @sumPrecioUni
end
go

create procedure ej8
as
begin
    create table diferenciasEj8 (
    articulo char(8),
	detalle char(50),
	cantidad int,
	precio_generado decimal(12,2),
	precio_facturado decimal(12,2) 
    )
    insert into diferenciasEj8
    select
        comp_producto, 
        prod_detalle, 
        count(comp_componente),
        dbo.precio_suma_unitaria(prod_codigo), 
        prod_precio
    from Composicion
    join Producto on comp_producto = prod_codigo
    group by comp_producto, prod_detalle, prod_precio, prod_codigo
end
go

/*
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
*/
create trigger ej9 on item_factura after insert
as
begin 
    declare @articulo char(8), @cant int, @depo char(2), @compo char(8), @cantCompo int

    if (select count(*) from inserted) > 0
        begin
            declare cAlta cursor for 
            select item_producto, item_cantidad
            from inserted
            join Composicion on item_producto = comp_producto

            open cAlta
            fetch next from cAlta into @articulo, @cant
            while @@fetch_status = 0
            begin
                declare cComp cursor for 
                select comp_componente, comp_cantidad
                from Composicion
                where comp_producto = @articulo

                open cComp 
                fetch next from cComp into @compo, @cantCompo
                while @@FETCH_STATUS = 0
                begin
                    set @depo = (
                        select top 1 stoc_deposito
                        from stock
                        where stoc_producto = @compo
                    )
                    update STOCK
                    set stoc_cantidad = stoc_cantidad - (@cantCompo * @cant)
                    where stoc_producto = @compo and stoc_deposito = @depo

                    fetch next from cComp into @compo, @cantCompo
                end
                close cComp
                deallocate cComp    
            end
            close cAlta
            DEALLOCATE cAlta
        end
end
go
/*
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/
create trigger ej10 on producto instead of delete
as 
begin
    if (
        select count(*) 
        from deleted d 
        join stock on d.prod_codigo = stoc_producto and stoc_cantidad > 0
        ) > 0
            begin
                print('No es posible borrar articulo con stock')
                ROLLBACK
            end 
        else 
            delete from Producto 
            where prod_codigo in (select prod_codigo from deleted)
end 
go


/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/

create or alter function ej11(@empleado numeric(6,0)) 
returns int
as 
begin 
    declare @subordinados int;
    declare @subDirecto numeric(6,0);

    declare cSub cursor for 
    select empl_codigo 
    from empleado  
    where empl_jefe = @empleado
    and empl_codigo > @empleado

    select @subordinados = count(*)
    from Empleado
    where empl_jefe = @empleado
    and empl_codigo > @empleado

    open cSub 
    fetch next from cSub into @subDirecto
    while @@FETCH_STATUS = 0
        begin
            set @subordinados = @subordinados + dbo.ej11(@subDirecto)
            fetch next from cSub into @subDirecto
        end
    
    close cSub
    deallocate cSub

    return @subordinados
end
go 


/*
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.
*/
create function ej12Func(@producto char(8), @componente char(8))
returns int
as
begin 
    if @producto = @componente 
        return 1
    else 
        declare @prodAux char(8)
        declare cComp cursor for
        select comp_componente 
        from Composicion 
        where comp_producto = @componente

        open cComp
        fetch next from cComp into @prodAux
        while @@FETCH_STATUS = 0
            begin
                if dbo.ej12Func(@componente, @prodAux) = 1
                    return 1
                fetch next from cComp into @prodAux
            end
        close cComp
        deallocate cComp
        return 0
end 
go


create trigger ej12 on composicion instead of insert, update
as 
begin 
    if(select sum(dbo.ej12Func(comp_producto, comp_componente)) from inserted) > 0
        begin
            print 'Un producto no puede estar compuesto por si mismo'
            rollback 
        end
    if(select count(*) from inserted) > 0 and (select count(*) from deleted) > 0
        begin
            update c
            set
                c.comp_producto = i.comp_producto,
                c.comp_componente = i.comp_componente,
                c.comp_cantidad = i.comp_cantidad
            from Composicion c
            JOIN inserted i on c.comp_producto = i.comp_producto
        end
    else
        begin
            insert into Composicion(comp_cantidad, comp_producto, comp_componente)
            select comp_Cantidad, comp_producto, comp_componente
            from inserted
        end 
end 
go


/*
13. Cree el/los objetos de base de datos necesarios para implementar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
*/
create function Ej13Func(@jefe numeric(6,0))
returns decimal(12,2)
begin
    declare @sumSuborSario numeric(12,2) = 0
    declare @suborSalario numeric(12,2)
    declare @suborDirecto numeric(6,0)

    if (select count(*) from Empleado where empl_jefe = @jefe) = 0
        return 0 

    declare cSubord cursor for
    select empl_codigo, empl_salario
    from Empleado
    where empl_jefe = @jefe

    open cSubord
    fetch next from cSubord into @suborDirecto, @suborSalario
    while @@FETCH_STATUS = 0
        begin 
            set @sumSuborSario = @sumSuborSario + @suborSalario + dbo.Ej13Func(@suborDirecto)
            fetch next from cSubord into @suborDirecto, @suborSalario
        end 
    close cSubord
    deallocate cSubord
    return @sumSuborSario
end 
go 


create trigger ej13 on Empleado after insert, update, delete
as 
begin
    if exists(select 1 from inserted where empl_salario > dbo.Ej13Func(empl_codigo) * 0.20) --Ej13Func devuelve sumatoria total de los empleados del jefe
        print 'Un jefe no puede tener un salario mayor al 20% de la suma de los salarios de los empleados'
        rollback
    if exists(select 1 from deleted where empl_salario > dbo.Ej13Func(empl_codigo) * 0.20)
        print 'Un jefe no puede tener un salario mayor al 20% de la suma de los salarios de los empleados'
        rollback
end 
go 


/*
14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.
*/


/*
PRECIO_COMPUESTO > SUMA_COMPONENTES * 0.5 && PRECIO_COMPUESTO < SUMA_COMPONENTES --> PRINTEAS E INSERTAS
PRECIO_COMPUESTO > SUMA_COMPONENTES * 0.5 && PRECIO_COMPUESTO > SUMA_COMPONENTES --> INSERTAS
PRECIO_COMPUESTO < SUMA_COMPONENTES --> NO INSERTAS Y DELETEAS TODO ITEM_FACTURA ASOCIADO A ESA FACTURA Y FINALMENTE DELETEAS FACTURA
*/
create function ej14Func(@producto char(8))
returns numeric(12,2)
as 
begin
    declare @sumPrecioComp numeric(12,2) = 0 
    declare @compo char(8), @cantidad decimal(12,2)

    if @producto not in (select comp_producto from Composicion)
        set @sumPrecioComp = (select prod_precio from Producto where prod_codigo = @producto)
    else 
        begin
            declare cComp cursor for
            select comp_componente, comp_cantidad from Composicion 
            where comp_producto = @producto

            open cComp 
            fetch next from cComp into @compo, @cantidad
            while @@FETCH_STATUS = 0
                begin 
                    set @sumPrecioComp = @sumPrecioComp + @cantidad * dbo.ej14Func(@compo)
                    fetch next from cComp into @compo, @cantidad
                end  
        close cComp
        deallocate cComp
        end
    return @sumPrecioComp
end 
go


create trigger ej14 on item_Factura instead of insert
as 
begin 
    declare @producto char(8), @precio numeric(12,2), @fecha smalldatetime, @cliente char(6)
    declare @type char(1), @sucursal char(4), @numero char(8), @cantidad decimal(12,2)

    declare cItem cursor for
    select fact_fecha, fact_cliente, item_producto, item_precio, item_tipo, item_sucursal, item_numero, item_cantidad
    from inserted
    join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 

    open cItem
    fetch next from cItem into @fecha, @cliente, @producto, @precio, @type, @sucursal, @numero, @cantidad
    while @@FETCH_STATUS = 0
    begin 
        if @precio > dbo.ej14Func(@producto) * 0.5 and @precio < dbo.ej14Func(@producto)
            begin 
                print(@fecha + ' ' + @cliente + ' ' + @producto + ' ' + @precio)
                insert into Item_Factura
                values(@type, @sucursal, @numero, @producto, @cantidad, @precio)
            end
        else
            begin
                if @precio > dbo.ej14Func(@producto)
                    insert into Item_Factura values(@type, @sucursal, @numero, @producto, @cantidad, @precio)
                else 
                    begin
                        delete from Item_Factura where item_tipo+item_sucursal+item_numero = @type+@sucursal+@numero
                        delete from Factura where fact_tipo+fact_sucursal+fact_numero = @type+@sucursal+@numero
                    end 
            end 
        fetch next from cItem into @fecha, @cliente, @producto, @precio, @type, @sucursal, @numero, @cantidad
    end 
    close cItem
    deallocate cItem
end 
go 


/*
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*/
create function ej15(@producto char(8))
returns decimal(12,2)
as 
begin
    declare @precio decimal(12,2) = 0
    declare @componente char(8), @cantidad decimal(12,2)

    if @producto not in (select comp_producto from Composicion)
        set @precio = (select prod_precio from Producto where prod_codigo = @producto)
    begin 
        declare cComp cursor for
        select comp_componente, comp_Cantidad
        from Composicion 
        where comp_producto = @producto

        open cComp
        fetch next from cComp into @componente, @cantidad
        while @@FETCH_STATUS = 0
            begin
                set @precio = @precio + @cantidad * dbo.ej15(@componente)
                fetch next from cComp into @componente, @cantidad
            end 
    end
    close cComp 
    deallocate cComp

    return @precio
end 
go 


/*
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.
*/
create trigger ej16 on item_Factura after insert
as
begin
    declare @producto char(8), @cantidad  decimal(12,2)
    declare @depo char(2)
    declare @cantDepo decimal(12,2)
    declare @lastDepo char(2)

    if exists(select 1 from inserted)
    begin
        declare cItems cursor for
        select item_producto, item_cantidad
        from inserted

        open cItems
        fetch next from cItems into @producto, @cantidad
        while @@FETCH_STATUS = 0 
        begin
            declare cDeposito cursor for
            select stoc_Deposito, stoc_cantidad
            from stock
            where stoc_producto = @producto
            order by stoc_cantidad desc

            open cDeposito
            fetch next from cDeposito into @depo, @cantDepo
            while @@FETCH_STATUS = 0 and @cantidad > 0
                begin
                    if @cantDepo >= @cantidad
                        begin
                            update stock
                            set stoc_cantidad = (@cantDepo - @cantidad)
                            where stoc_deposito = @depo
                            and stoc_producto = @producto
                            SET @cantidad = 0;
                            FETCH NEXT FROM cDeposito INTO @depo, @cantDepo;
                        end
                    else
                        begin
                            update stock
                            set stoc_cantidad = 0
                            where stoc_deposito = @depo
                            and stoc_producto = @producto
                            set @cantidad = @cantidad - @cantDepo 
                            set @lastDepo = @depo
                            fetch next from cDeposito into @depo, @cantDepo 
                        end
                end
            if @cantidad > 0
                begin
                    update stock
                    set stoc_cantidad = stoc_cantidad - @cantidad
                    where stoc_deposito = @lastDepo
                    and stoc_producto = @producto 
                end 
            close cDeposito
            deallocate cDeposito
            fetch next from cItems into @producto, @cantidad         
        end
        close cItems
        deallocate cItems
    end
end 
go


/*
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
*/
create trigger ej17 on stock after update 
as 
begin
    if exists(select 1 from inserted where stoc_cantidad < stoc_punto_reposicion or stoc_cantidad >= stoc_stock_maximo)
        begin
            print 'Stock invalido'
            rollback 
        end 
end 
go 


/*
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/
create function ej18Func(@cliente char(6))
returns decimal(12,2)
as
begin
    declare @totalFacturado decimal(12,2) = 0
    declare @fact_total decimal(12,2)

    declare cFact cursor for
    select fact_total
    from factura 
    where fact_cliente = @cliente and MONTH(fact_fecha) = MONTH(getdate())
    and year(fact_fecha) = YEAR(GETDATE())

    open cFact
    fetch next from cFact into @fact_total
    while @@FETCH_STATUS = 0
        begin
            set @totalFacturado =  @totalFacturado + @fact_total
            FETCH next from cFact into @fact_total
        end
    close cFact
    DEALLOCATE cFact
    return @totalFacturado
end 
go

create trigger ej18 on Factura after insert
as 
begin
    if exists(
        select 1 from inserted i 
        join Cliente on i.fact_cliente = clie_codigo
        where clie_limite_credito < dbo.ej18Func(fact_cliente) + i.fact_total
    )
        begin
            print 'Ya se ha cobrado el monto maximo mensual para este cliente'
            delete from Factura
            where fact_tipo+fact_sucursal+fact_numero = (select fact_tipo+fact_sucursal+fact_numero from inserted)

            delete from Item_Factura
            where item_tipo+item_sucursal+item_numero = (select fact_tipo+fact_sucursal+fact_numero from inserted)
        end 
end
go


/*
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.
*/
create function ej19Func(@jefe numeric(6,0))
returns int
as 
begin
    declare @empleado numeric(6,0)
    declare @cantSubordinados int

    declare cSubordinado cursor for
    select empl_codigo
    from Empleado
    where empl_jefe = @jefe

    select @cantSubordinados = count(*)
    from Empleado
    where empl_jefe = @jefe

    open cSubordinado
    fetch next from cSubordinado into @empleado
    while @@FETCH_STATUS = 0
        begin
            set @cantSubordinados = @cantSubordinados + dbo.ej19Func(@empleado)
            fetch next from cSubordinado into @empleado 
        end 
    close cSubordinado
    deallocate cSubordinado

    return @cantSubordinados
end 
go


--Asumo que es un or, pero podria ser un and...
--Es un tema de interpretacion de consigna, no es relevante al problema.
create trigger ej19 on Empleado after insert
as 
begin
    if exists(
        select 1 from inserted e
        join Empleado j on e.empl_jefe = j.empl_codigo and e.empl_jefe is not null
        where DATEDIFF(year, j.empl_ingreso, getdate()) < 5
        or dbo.ej19Func(j.empl_codigo) > (select count(*) from Empleado) * 0.5  
    )
        begin
            print 'Un jefe debe tener mas de 5 años de antiguedad y no puede tener mas 
            de la mitad de los empleados a cargo (salvo el gerente general)'
            rollback
        end
end
go

/*
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
*/
create procedure ej20 
as  
begin 
    declare @empleado numeric(6,0)
    declare @comision decimal(12,2)

    declare cEmp cursor for
    select empl_codigo
    from Empleado

    open cEmp
    fetch next from cEmp into @empleado
    while @@FETCH_STATUS = 0
        begin 
            set @comision = 0.05 * (
                                    select sum(isnull(fact_total, 0)) 
                                    from Factura 
                                    where fact_vendedor = @empleado 
                                    and year(fact_fecha) = year(GETDATE())
                                    and MONTH(fact_fecha) = month(GETDATE())
                                    )
            if (
                select count(distinct item_producto) 
                from factura
                join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero 
                where fact_vendedor = @empleado and year(fact_fecha) = year(GETDATE()) and MONTH(fact_fecha) = month(GETDATE())
            ) >= 50
                begin 
                    set @comision = @comision + 0.03  * (
                                    select sum(isnull(fact_total, 0)) 
                                    from Factura 
                                    where fact_vendedor = @empleado 
                                    and year(fact_fecha) = year(GETDATE())
                                    and MONTH(fact_fecha) = month(GETDATE())
                                    )
                end 
            
            update Empleado
            set empl_comision = @comision
            where empl_codigo = @empleado

            fetch next from cEmp into @empleado
        end 
    close cEmp
    deallocate cEmp
end
go


/*
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.
*/
create trigger ej21 on Factura instead of insert
as
begin 
    if exists
        (
            select 1 
            from inserted i 
            join Item_Factura on i.fact_tipo+i.fact_sucursal+i.fact_numero = item_tipo+item_sucursal+item_numero
            join Producto on item_producto = prod_codigo
            group by  item_tipo, item_sucursal, item_numero
            having count(distinct prod_familia) > 1      
        )
        begin 
            delete from Item_Factura where item_tipo+item_sucursal+item_numero = (select fact_tipo+fact_sucursal+fact_numero from inserted)
            RAISERROR('No puede comprarse productos de distintas familias en una misma factura', 16,1)
        end
    else
        begin 
            insert into Factura(fact_tipo, fact_sucursal, fact_numero, fact_fecha, fact_vendedor, fact_total, fact_total_impuestos, fact_cliente)
            select fact_tipo, fact_sucursal, fact_numero, fact_fecha, fact_vendedor, fact_total, fact_total_impuestos, fact_cliente
            from inserted
        end 
end 
go


/*
22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.
*/
create procedure ej22
as 
begin
    declare @rubro char(4)
    declare @freeRubro char(4)
    declare @cant_reasignar int
    declare @freeCant int 
    declare @newRubroID char(4)

    declare cRubro cursor for
    select rubr_id, (select count(*) from producto where prod_rubro = rubr_id) - 20
    from rubro 
    where (select count(*) from producto where prod_rubro = rubr_id) > 20

    open cRubro
    fetch next from cRubro into @rubro, @cant_reasignar

    while @@FETCH_STATUS = 0
        begin
            declare cRubroLibre cursor for
            select rubr_id, 20 - (select count(*) from producto where prod_rubro = rubr_id)
            from rubro 
            where (select count(*) from producto where prod_rubro = rubr_id) < 20

            open cRubroLibre
            fetch next from cRubroLibre into @freeRubro, @freeCant
            while @@FETCH_STATUS = 0 and @cant_reasignar > 0
                begin
                    if @freeCant > @cant_reasignar
                        begin
                            update Producto
                            set prod_rubro = @freeRubro
                            where prod_codigo in (select top (@cant_reasignar) prod_codigo from Producto where prod_rubro = @rubro)
                            set @cant_reasignar = 0
                        end
                    else
                        begin
                            update Producto
                            set prod_rubro = @freeRubro
                            where prod_codigo in (select top (@freeCant) prod_codigo from Producto where prod_rubro = @rubro)
                            set @cant_reasignar = @cant_reasignar - @freeCant
                        end 
                    fetch from cRubroLibre into @freeRubro, @freeCant
                end
                if @cant_reasignar > 0
                    begin
                        SELECT @newRubroID = RIGHT('000' + CAST(ISNULL(MAX(CAST(rubr_id AS INT)), 0) + 1 AS VARCHAR), 4)
                        FROM Rubro

                        insert into Rubro(rubr_id, rubr_detalle)
                        values(@newRubroID, 'RUBRO REASIGNADO')

                        update Producto
                        set prod_rubro = @newRubroID
                        where prod_codigo in (select top (@cant_reasignar) prod_codigo from Producto where prod_rubro = @rubro)
                    end
                close cRubroLibre
                deallocate cRubroLibre
            fetch next from cRubro into @rubro, @cant_reasignar
        end
    close cRubro
    deallocate cRubro
end 
go 

drop PROCEDURE ej22

begin TRANSACTION
    select rubr_id, count(distinct prod_codigo) from Rubro
    join Producto on rubr_id = prod_rubro
    group by rubr_id
    order by rubr_id

    exec dbo.ej22

    select rubr_id, count(distinct prod_codigo) from Rubro
    join Producto on rubr_id = prod_rubro
    group by rubr_id
    order by rubr_id

ROLLBACK
go


--Recorre rubro a rubro
--Verifico si rubro tiene mas de 20 productos
--Tiene mas de 20
    --SELECCIONO 20 PRODUCTOS QUE SE QUEDAN
    --RESTO DE PRODUCTO DIVIDO ENTRE LOS RUBROS QUE ENTRE
    --SI ME SOBRA CANTIDAD CREO NUEVO RUBRO
--No tiene mas de 20
    --Paso a siguiente

/*
23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.
*/
create trigger ej23 on Item_Factura after insert
as 
begin 
    if exists
        (
            select 1 
            from Item_Factura i
            join composicion on i.item_producto = comp_producto
            group by item_numero+item_tipo+item_sucursal
            having count(distinct item_producto) > 2
        )
        begin
            delete from Item_Factura where item_tipo+item_sucursal+item_numero in (select item_tipo+item_sucursal+item_numero from inserted) 
            delete from Factura where fact_tipo+fact_sucursal+fact_numero in (select item_tipo+item_sucursal+item_numero from inserted) 
        end 
end 
go

/*
24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.
*/
create procedure ej24
as
begin 
    declare @depo char(2), @zona char(3)
    declare @newEncargado numeric(6,0)

    declare cDeposito cursor for
    select depo_codigo, depo_zona
    from deposito
    join Empleado on depo_encargado = empl_codigo
    join Departamento on empl_departamento = depa_codigo 
    where depo_zona <> depa_zona

    open cDeposito
    fetch next from cDeposito into @depo, @zona
    while @@FETCH_STATUS = 0
        begin 
            set @newEncargado = 
                            (
                                select top 1 empl_codigo 
                                from Empleado 
                                join Deposito on depo_encargado = empl_codigo and depo_zona = @zona 
                                join Departamento on empl_departamento = depa_codigo and depa_zona = @zona
                                group by empl_codigo
                                order by count(empl_codigo) asc
                            )
            update DEPOSITO
            set depo_encargado = @newEncargado
            where depo_codigo = @depo 

            fetch next from cDeposito into @depo, @zona, @encargado
        end 
    close cDeposito
    deallocate cDeposito
end 
go

/*
25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A 
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.
*/

create function ej25Func(@producto char(8))
returns int 
as 
begin 
    declare @comp char(8)
    declare @compRecur int = 0

    declare cComp cursor for
    select comp_componente
    from Composicion where @producto = comp_producto

    open cComp
    fetch next from cComp into @comp
    while @@FETCH_STATUS = 0 and @compRecur = 0
        begin
            if @producto in (select comp_componente from Composicion where comp_producto = @comp)
                set @compRecur = 1
            else if dbo.ej25Func(@comp) = 1
                set @compRecur = 1
            
            FETCH next from cComp into @comp
        end 
    close cComp
    deallocate cComp
    return @compRecur
end 
go 


create trigger ej25 on Composicion after insert
as 
begin
    if exists(select 1 from inserted where dbo.ej25Func(comp_producto) = 1)
        begin 
            print 'La composicion no puede ser recursiva'
            ROLLBACK
        end 
end 
go


/*
26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
*/
create trigger ej26 on item_Factura after insert
as 
begin 
    if exists
        (
        select 1 from inserted i 
        where item_producto in 
                    (
                        select comp_componente 
                        from Composicion 
                        join Item_Factura on comp_producto = item_producto 
                        where item_tipo+item_sucursal+item_numero = i.item_tipo+i.item_sucursal+i.item_numero
                    )
        )
        begin
            delete Item_Factura where item_tipo+item_sucursal+item_numero in (select i.item_tipo+i.item_sucursal+i.item_numero from inserted i)
            delete Factura where fact_tipo+fact_sucursal+fact_numero in (select i.item_tipo+i.item_sucursal+i.item_numero from inserted i)
            ROLLBACK
        end 
end
go 
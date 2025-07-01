--No tengo idea la fecha del parcial

/*
Implementar el/los objetos necesarios para implementar la siguiente restriccion en linea:
Cuando se inserta en una venta un COMBO, nunca se debera guardar el producto COMBO, sino, la descomposicion de sus componentes.
 Nota: Se sabe que actualmente todos los articulos guardados de ventas estan descompuestos en sus componentes.
*/
create trigger parcial on Item_Factura instead of insert
as 
begin 
    declare @compo char(8), @cantidad decimal(12,2), @precio decimal(12,2)
    
    if exists(select 1 from inserted where item_producto in (select comp_producto from Composicion))

        declare cComp cursor for
        select comp_componente, comp_cantidad, prod_precio
        from Composicion
        join Producto on comp_producto = prod_codigo
        where comp_producto = (select item_producto from inserted)

        open cComp 
        fetch next from cComp into @compo, @cantidad, @precio
        while @@FETCH_STATUS = 0
            begin 
                insert into Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                select item_tipo, item_sucursal, item_numero, @compo, @cantidad, @precio
                from inserted

                fetch next from cComp into @compo, @cantidad, @precio
            end
        close cComp
        deallocate cComp
end 
go 


/*
Implementar un sistema de auditoria para registrar cada operacion realizada en la tabla 
cliente. El sistema debera almacenar, como minimo, los valores(campos afectados), el tipo 
de operacion a realizar, y la fecha y hora de ejecucion. SOlo se permitiran operaciones individuales
(no masivas) sobre los registros, pero el intento de realizar operaciones masivas deberá ser registrado
en el sistema de auditoria
*/
create table auditoria(
    audi_operacion char(100),
    audi_codigo char(6),
    audi_razon_social char(10),
    audi_telefono char(100),
    audi_domicilio char(100),
    audi_limite_credito decimal(12, 2),
    audi_vendedor numeric(6), 
    fecha smalldatetime, 
    hora  int
)
go 

create trigger parcial2 on Cliente after insert
as 
begin
    if (select count(*) from inserted) > 1
        begin
            print 'No se permiten operaciones masivas'
            rollback
        end
    else
        begin
            insert into auditoria
                        (
                            audi_operacion, audi_codigo, 
                            audi_razon_social, audi_telefono, 
                            audi_domicilio, audi_limite_credito, 
                            audi_vendedor, fecha, hora
                        )
            select 'Insercion', clie_codigo, clie_razon_social, clie_telefono, clie_domicilio, clie_limite_credito, clie_vendedor
            from inserted 
        end
end 
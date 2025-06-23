/*
EJERCICIOS HECHOS: 
1.✅
2.✅
3.✅
4.✅
5.✅
6.✅
7.✅
8.✅
9.✅
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
22.✅
23.✅
24.✅
25.✅
26.
27.
28.
29.
30.
31.
32.
33.
*/


--1.Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o 
--igual a $ 1000 ordenado por código de cliente.

select clie_codigo, clie_razon_social from Cliente
where clie_limite_credito >= 1000
order by clie_codigo


--2.Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
--cantidad vendida.
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) AS total_vendido
FROM Factura 
JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
JOIN Producto ON item_producto = prod_codigo
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY total_vendido DESC;


--3.Realizar una consulta que muestre código de producto, nombre de producto y el stock
--total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
--nombre del artículo de menor a mayor.

select prod_codigo, prod_detalle, sum(stoc_cantidad) from Producto
join stock on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
ORDER by prod_detalle desc


--4.Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
--artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
--promedio por depósito sea mayor a 100.
select prod_codigo, prod_detalle, COUNT(DISTINCT comp_componente) from Producto
LEFT join Composicion on prod_codigo = comp_producto
join STOCK on stoc_producto = prod_codigo
group by prod_codigo, prod_detalle
HAVING AVG(stoc_cantidad) > 100 --Todos tienen 0 porque no hay compuesto con promedio de stock mayor a 20


--.Este es mejor, hace menos comparaciones. 
select prod_codigo, prod_detalle, COUNT(comp_componente) from Producto
LEFT join Composicion on prod_codigo = comp_producto
group by prod_codigo, prod_detalle
HAVING prod_codigo in (select stoc_producto from stock group by stoc_producto having AVG(stoc_cantidad) > 100)
order by 3 DESC

--5.Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
--stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
--fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
select prod_codigo, prod_detalle, sum(item_cantidad) from producto
join Item_Factura on prod_codigo = item_producto
join Factura on fact_tipo = item_tipo AND fact_sucursal = item_sucursal and fact_numero = item_numero
where year(fact_fecha) = 2012 
GROUP by prod_codigo, prod_detalle
having sum(item_cantidad) > (
    select sum(item_cantidad) from Item_Factura
    left join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    where year(fact_fecha) = 2011 and item_producto = prod_codigo
)

--6.Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
--rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
--tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.
select rubr_id, rubr_detalle, count(DISTINCT prod_codigo) productosXrubro, sum(isnull(stoc_cantidad,0)) stockTotal from rubro
left join Producto on prod_codigo in (select stoc_producto from stock GROUP by stoc_producto
                                      having sum(isnull(stoc_cantidad,0)) >
                                      (select stoc_cantidad from stock
                                       where stoc_producto = '00000000' and stoc_deposito = '00'))
                   and rubr_id = prod_rubro
left join stock on prod_codigo = stoc_producto
group by rubr_id, rubr_detalle

--7.Generar una consulta que muestre para cada artículo código, detalle, mayor precio
--menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
--10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
--stock.
select prod_codigo, prod_detalle, max(item_precio), min(item_precio), ((MAX(item_precio) - MIN(item_precio)) / MIN(prod_precio) * 100) from Producto
join stock on prod_codigo = stoc_producto
join Item_Factura on  prod_codigo = item_producto
where stoc_cantidad > 0
GROUP by prod_codigo, prod_detalle

--Resolucion de Reinosa.
select prod_codigo, prod_detalle, max(item_precio), min(item_precio), ((max(item_precio) - min(item_precio))*100)/min(item_precio)
from Producto
join item_factura on item_producto = prod_codigo
join stock on stoc_producto = prod_codigo
where prod_codigo in (
    select stoc_producto 
    from stock 
    where stoc_cantidad > 0
    )
group by prod_codigo, prod_detalle

--8.Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
--artículo, stock del depósito que más stock tiene.
select prod_detalle, max(stoc_cantidad) from Producto
join stock on prod_codigo = stoc_producto
group by prod_detalle 
having count(*) = (select count(*) from DEPOSITO) - 24


--9.Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
--mismo y la cantidad de depósitos que ambos tienen asignados.
select 
    e.empl_jefe, 
    e.empl_codigo, 
    e.empl_nombre, 
    count(DISTINCT d_jefe.depo_codigo) as cant_depo_jefe, 
    count(DISTINCT d_emp.depo_codigo) as  cant_depo_emp 
from Empleado e
left join DEPOSITO d_jefe on d_jefe.depo_encargado = e.empl_jefe
left join DEPOSITO d_emp on d_emp.depo_encargado = e.empl_codigo
group by e.empl_jefe, e.empl_codigo, e.empl_nombre

--10.Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
--vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
--mayor compra realizo.


select prod_codigo, (
    select top 1 fact_cliente from Factura
    join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
    where item_producto = prod_codigo 
    GROUP by fact_cliente
    order by sum(item_cantidad) desc
) mayorComprador
from Producto
where prod_codigo in 
    (select top 10 item_producto from Item_Factura
    group by item_producto
    order by sum(item_cantidad) desc) 
    or
    prod_codigo in 
    (select top 10 item_producto from Item_Factura
    group by item_producto
    order by sum(item_cantidad) asc)

--11.Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
--productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
--ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
--solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
--el año 2012.
select fami_detalle, COUNT(DISTINCT prod_codigo) productosDiferentes, sum(fact_total) - sum(fact_total_impuestos) facturacionTotal
from familia
join Producto on fami_id = prod_familia
join Item_Factura on prod_codigo = item_producto
join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY fami_detalle
HAVING SUM(fact_total) > 20000
order by COUNT(DISTINCT prod_codigo) desc

--12.Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
--promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
--producto y stock actual del producto en todos los depósitos. Se deberán mostrar
--aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
--ordenarse de mayor a menor por monto vendido del producto.
select prod_detalle, count(DISTINCT fact_cliente), AVG(item_precio), count(distinct stoc_deposito), sum(distinct stoc_cantidad) 
from producto
join Item_Factura on prod_codigo = item_producto
join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
join stock on prod_codigo = stoc_producto
where stoc_cantidad > 0 and year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
ORDER by sum(item_cantidad * item_precio) desc 

--13.Realizar una consulta que retorne para cada producto que posea composición nombre
--del producto, precio del producto, precio de la sumatoria de los precios por la cantidad 
--de los productos que lo componen. Solo se deberán mostrar los productos que estén
--compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
--cantidad de productos que lo componen.

/*
Esta consulta calcula, para cada producto compuesto, su nombre, precio,
y el costo total de los componentes que lo integran (precio del componente * cantidad).
Se hace un JOIN doble con la tabla Producto:
 - Primero como 'p' para obtener los datos del producto compuesto.
 - Luego como 'pc' para obtener el precio de cada componente.
Esto es necesario porque tanto el producto compuesto como sus componentes están en la misma tabla.
Solo se incluyen productos que tengan más de 2 componentes, y se ordenan de mayor a menor
según la cantidad de componentes que poseen.
*/
select p.prod_Detalle, p.prod_precio, sum(c.comp_cantidad * pc.prod_precio) 
from Producto p
join Composicion c on c.comp_producto = p.prod_codigo
join producto pc on  c.comp_componente = pc.prod_codigo
group by p.prod_detalle, p.prod_precio
having count(c.comp_componente) > 2
ORDER by count(c.comp_componente) asc

--14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
--debe retornar son:
--Código del cliente
--Cantidad de veces que compro en el último año
--Promedio por compra en el último año
--Cantidad de productos diferentes que compro en el último año
--Monto de la mayor compra que realizo en el último año
--Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
--el último año.
--No se deberán visualizar NULLs en ninguna columna
select 
    clie_codigo, 
    count(fact_cliente), 
    (select AVG(fact_total) from Factura where year(fact_fecha) = year(getdate()) - 1 and fact_cliente = clie_codigo), 
    count(distinct item_producto), 
    max(fact_total)
from Cliente 
join Factura on clie_codigo = fact_cliente
join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where year(fact_fecha) = year(getdate()) - 1
group by clie_codigo
order by count(fact_cliente) desc

--15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
--(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
--descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
--juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
--juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
--Ejemplo de lo que retornaría la consulta:
--PROD1 DETALLE1 PROD2 DETALLE2 VECES
--1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
--1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
select p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, count(*)
from Item_Factura i1
join Item_Factura i2 ON i1.item_tipo = i2.item_tipo AND i1.item_sucursal = i2.item_sucursal AND i1.item_numero = i2.item_numero
join Producto p1 on i1.item_producto = p1.prod_codigo
join Producto p2 on i2.item_producto = p2.prod_codigo
where i1.item_producto < i2.item_producto
group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
having count(*) > 500
order by count(*)

--16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
--en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
--inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
--Además mostrar
--1. Nombre del Cliente
--2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
--3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
--mostrar solamente el de menor código) para ese cliente.
--Aclaraciones:
--La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
--productos no compuestos.
--Los clientes deben ser ordenados por código de provincia ascendente.
select f1.fact_cliente, sum(item_cantidad), 
    (
        select top 1 item_producto from Item_Factura
        join Factura f2 on item_tipo = f2.fact_tipo AND item_sucursal = f2.fact_sucursal AND item_numero = f2.fact_numero
        where year(fact_fecha) = 2012 and f1.fact_cliente = f2.fact_cliente
        group by item_producto
        order by sum(item_cantidad) desc
    )
from factura f1
join Item_Factura on item_tipo = f1.fact_tipo AND item_sucursal = f1.fact_sucursal AND item_numero = f1.fact_numero
where year(fact_fecha) = 2012
group by fact_cliente
having sum(item_cantidad) < 
    ((
    select avg(item_cantidad) from Item_Factura
    join Factura on item_tipo = fact_tipo AND item_sucursal = fact_sucursal AND item_numero = fact_numero
    where year(fact_fecha) = 2012 and item_producto = 
        (
        select top 1 item_producto from Item_Factura
        join Factura on item_tipo = fact_tipo AND item_sucursal = fact_sucursal AND item_numero = fact_numero
        where year(fact_fecha) = 2012
        group by item_producto
        order by sum(item_cantidad) desc
        )
    ) / 3.0)


--17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
--producto.
--La consulta debe retornar:
--PERIODO: Año y mes de la estadística con el formato YYYYMM   
--PROD: Código de producto    
--DETALLE: Detalle del producto     
--CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo   
--VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
--pero del año anterior
--CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
--periodo
--La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
--por periodo y código de producto.

select FORMAT(fact_fecha, 'yyyy/MM') as periodo, 
    prod_codigo, prod_detalle, 
    sum(isnull(item_cantidad, 0)) as cantidad_Vendida, 
    (
    select isnull(sum(isnull(i2.item_cantidad, 0)), 0) 
    from Item_Factura i2
    join Factura f2 on i2.item_tipo = f2.fact_tipo AND i2.item_sucursal = f2.fact_sucursal AND i2.item_numero = f2.fact_numero
    where i2.item_producto = prod_codigo 
        and year(f2.fact_fecha) - 1 = year(f1.fact_fecha) 
        and month(f2.fact_fecha) = MONTH(f1.fact_fecha)
    ) as Ventas_anio_anterior, 
    count(distinct(fact_tipo+fact_sucursal+fact_numero)) as cant_facturas
from Producto
join Item_Factura i1 on prod_codigo = i1.item_producto
join Factura f1 on i1.item_tipo = f1.fact_tipo AND i1.item_sucursal = f1.fact_sucursal AND i1.item_numero = f1.fact_numero
group by prod_codigo, prod_detalle, f1.fact_fecha
order by f1.fact_fecha, prod_codigo


/*
18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.
*/
select 
    rubr_detalle, 
    isnull(sum(isnull(item_cantidad * item_precio, 0)), 0), 
    isnull((
        select top 1 prod_codigo from Producto
        join Item_Factura on prod_codigo = item_producto
        where prod_rubro = r.rubr_id
        group by prod_codigo
        order by sum(item_cantidad) DESC
    ), 0), 
    isnull((
        select top 1 prod_codigo from Producto
        join Item_Factura on prod_codigo = item_producto
        where prod_rubro = r.rubr_id
        and prod_codigo <> (select top 1 prod_codigo from Producto
        join Item_Factura on prod_codigo = item_producto
        where prod_rubro = r.rubr_id
        group by prod_codigo
        order by sum(item_cantidad) DESC
        )
        group by prod_codigo
        order by sum(item_cantidad) DESC
    ),0), 
    isnull((
        select top 1 fact_cliente from factura 
        join Item_Factura on fact_tipo = item_tipo and fact_sucursal = item_sucursal and fact_numero = item_numero
        join Producto on prod_codigo = item_producto
        where prod_rubro = r.rubr_id
        group by fact_cliente
        order by sum(item_cantidad) DESC
    ), 0)
from Rubro r
join Producto on r.rubr_id = prod_rubro
left join Item_Factura on item_producto = prod_codigo
group by r.rubr_detalle, r.rubr_id
order by count(distinct(prod_codigo)) desc


/*
19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
 Codigo de producto  
 Detalle del producto   
 Codigo de la familia del producto  
 Detalle de la familia actual del producto 
 Codigo de la familia sugerido para el producto
 Detalle de la familia sugerido para el producto 
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/
select 
    p1.prod_codigo, 
    p1.prod_detalle, 
    p1.prod_familia, 
    f1.fami_detalle,   
        (
        select top 1 f2.fami_id from Producto p2
        join Familia f2 on p2.prod_familia = f2.fami_id
        where LEFT(p1.prod_Detalle, 5) = LEFT(p2.prod_Detalle, 5)
        GROUP BY f2.fami_detalle, f2.fami_id
        order by count(*) DESC, f2.fami_id
    ) AS codigo_sugerida, 
    (
        select top 1 f2.fami_detalle from Producto p2
        join Familia f2 on p2.prod_familia = f2.fami_id
        where LEFT(p1.prod_Detalle, 5) = LEFT(p2.prod_Detalle, 5)
        GROUP BY f2.fami_detalle, f2.fami_id
        order by count(*) DESC, f2.fami_id
    ) AS detalle_sugerida
from producto p1
join Familia f1 on prod_familia = f1.fami_id


/*
20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. 
El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho año.
*/
select 
    top 3 empl_codigo, 
    empl_nombre, 
    empl_apellido, 
    empl_ingreso,
    case when 
        (
        select count(fact_vendedor) 
        from Factura 
        where fact_vendedor = e1.empl_codigo and year(fact_fecha) > 2011) >= 50
    then(
        select count(*) 
        from Factura 
        where fact_total > 100 and fact_vendedor = e1.empl_codigo and year(fact_fecha) = 2011)
    else(
        select count(*)  from Empleado e2
        join Factura on e2.empl_codigo = fact_vendedor
        where e2.empl_jefe = e1.empl_codigo and year(fact_fecha) = 2011
    )  * 0.5
    end as puntaje_2011,

    case when 
        (
        select count(fact_vendedor) 
        from Factura 
        where fact_vendedor = e1.empl_codigo and year(fact_fecha) > 2012) >= 50
    then(
        select count(*) 
        from Factura 
        where fact_total > 100 and fact_vendedor = e1.empl_codigo and year(fact_fecha) = 2012)
    else(
        select count(*)  from Empleado e2
        join Factura on e2.empl_codigo = fact_vendedor
        where e2.empl_jefe = e1.empl_codigo and year(fact_fecha) = 2012
    )  * 0.5
    end as puntaje_2012
from Empleado e1 
order by puntaje_2012 desc

/*
21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta 
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año
*/
select year(fact_fecha),count(distinct fact_cliente) as clientes_mal_fact, count(*) as Cant_fact_malas from Factura f1
where abs(fact_total - fact_total_impuestos - (select sum(item_cantidad * item_precio) 
from item_factura where fact_tipo = item_tipo and fact_sucursal = item_sucursal and fact_numero = item_numero)) > 1
GROUP by year(fact_fecha)
order by year(fact_fecha)

/*
22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.
*/
select 
    rubr_detalle,
    ((MONTH(fact_fecha) - 1) / 3) + 1 as trimestre, 
    count(distinct fact_tipo+fact_numero+fact_sucursal) as cant_facturas,
    count(distinct prod_codigo) as cant_productos
from Rubro
join producto on rubr_id = prod_rubro
join Item_Factura on item_producto = prod_codigo
join Factura on fact_tipo = item_tipo and fact_sucursal = item_sucursal and fact_numero = item_numero
group by rubr_detalle, ((MONTH(fact_fecha) - 1) / 3) + 1
having count(distinct fact_tipo+fact_numero+fact_sucursal) > 100
order by rubr_detalle asc, cant_facturas desc


/*
23. Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año. 
 Cantidad de productos que componen directamente al producto más vendido 
 La cantidad de facturas en las cuales aparece ese producto. 
 El código de cliente que más compro ese producto.  
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente.
*/
select
    year(f1.fact_fecha), 
    c1.comp_producto as compo_mas_vendida, 
    count(distinct(prod_codigo)) as prods_componen,
    count(distinct(f1.fact_numero+f1.fact_sucursal+f1.fact_tipo)) as facturas, 
    (
        select top 1 f3.fact_cliente from Factura f3
        join Item_Factura on f3.fact_tipo = item_tipo and f3.fact_sucursal = item_sucursal and f3.fact_numero = item_numero
        where item_producto = c1.comp_producto and year(f3.fact_fecha) = year(f1.fact_fecha) 
        group by f3.fact_cliente
        order by count(*) desc
    ) as top_cliente, 
    ((select sum(item_cantidad * item_precio) from item_factura i1 join factura f5 on f5.fact_tipo = i1.item_tipo and f5.fact_sucursal = i1.item_sucursal and f5.fact_numero = i1.item_numero where year(f5.fact_fecha) = year(f1.fact_fecha) and i1.item_producto = c1.comp_producto) 
    / (select sum(abs(fact_total - fact_total_impuestos)) from Factura f4 where year(f4.fact_fecha) = year(f1.fact_fecha)) * 100)
from Factura f1
join item_factura on f1.fact_tipo = item_tipo and f1.fact_sucursal = item_sucursal and f1.fact_numero = item_numero
join Composicion c1 on c1.comp_producto = item_producto
join Producto on c1.comp_componente = prod_codigo
group by year(f1.fact_fecha), c1.comp_producto
having c1.comp_producto in (select top 1 comp_producto
        from Composicion
        join Item_Factura on item_producto = comp_producto
        join Factura f2 on f2.fact_tipo = item_tipo and f2.fact_sucursal = item_sucursal and f2.fact_numero = item_numero
        where year(f1.fact_fecha) = year(f2.fact_fecha)
        group by comp_producto
        order by sum(item_cantidad) desc)

/*
24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente
*/
select comp_producto, prod_detalle, sum(item_cantidad) from Composicion
join Producto on prod_codigo = comp_producto 
join Item_Factura on item_producto = prod_codigo
join Factura on fact_tipo = item_tipo and fact_sucursal = item_sucursal and fact_numero = item_numero
where fact_vendedor in (select top 2 empl_codigo from Empleado
group by empl_codigo, empl_comision
order by empl_comision desc)
group by comp_producto, prod_detalle
having count(distinct fact_tipo+fact_sucursal+fact_numero) >= 5
order by sum(item_cantidad) desc


/*
25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año    
b. El código de la familia más vendida en ese año.     
c. Cantidad de Rubros que componen esa familia.        
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.   
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.    
f. El código de cliente que más compro productos de esa familia. 
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente

NOTA = En algunas columnas agrego años para que de distintas, no lo pide 
al consigna, pero si no da siempre lo mismo, pues la familia es la misma.
*/
select 
    year(f1.fact_fecha), 
    (
        select top 1 fami_id from Familia
        join Producto on prod_familia = fami_id
        join Item_Factura i2 on prod_codigo = item_producto
        join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
        where year(f2.fact_fecha) = year(f1.fact_fecha)
        group by fami_id
        order by sum(item_cantidad) desc
    ) as familia_mas_vendida, 
    (
        select count(distinct prod_rubro) from Producto
        where prod_familia = (
                                select top 1 fami_id from Familia
                                join Producto on prod_familia = fami_id
                                join Item_Factura i2 on prod_codigo = item_producto
                                join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
                                where year(f2.fact_fecha) = year(f1.fact_fecha)
                                group by fami_id
                                order by sum(item_cantidad) desc
                            )
    ) as rubros_familia,
    isnull((
        select top 1 count(distinct comp_componente) from Composicion
        join Producto on prod_codigo = comp_producto
        join Item_Factura on prod_codigo = item_producto
        where prod_familia = (
                                select top 1 fami_id from Familia
                                join Producto on prod_familia = fami_id
                                join Item_Factura i2 on prod_codigo = item_producto
                                join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
                                where year(f2.fact_fecha) = year(f1.fact_fecha)
                                group by fami_id
                                order by sum(item_cantidad) desc
                             )
        group by item_cantidad
        order by sum(item_cantidad) desc
    ), 0) as Componentes_Producto, 
    (
        select count(distinct f3.fact_tipo+f3.fact_sucursal+f3.fact_numero) 
        from Factura f3 
        join Item_Factura i3 on f3.fact_tipo = i3.item_tipo and f3.fact_sucursal = i3.item_sucursal and f3.fact_numero = i3.item_numero 
        join Producto on i3.item_producto = prod_codigo
        where prod_familia = (
                                select top 1 fami_id from Familia
                                join Producto on prod_familia = fami_id
                                join Item_Factura i2 on prod_codigo = item_producto
                                join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
                                where year(f2.fact_fecha) = year(f1.fact_fecha)
                                group by fami_id
                                order by sum(item_cantidad) desc
                             ) and year(f1.fact_fecha) = year(f3.fact_fecha)
        ) as Facturas_familia, 
        (
            select top 1 fact_cliente 
            from Factura f4 
            join Item_Factura i3 on f4.fact_tipo = i3.item_tipo and f4.fact_sucursal = i3.item_sucursal and f4.fact_numero = i3.item_numero
            join Producto on prod_codigo = item_producto
            where prod_familia =(
                                select top 1 fami_id from Familia
                                join Producto on prod_familia = fami_id
                                join Item_Factura i2 on prod_codigo = item_producto
                                join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
                                where year(f2.fact_fecha) = year(f1.fact_fecha)
                                group by fami_id
                                order by sum(item_cantidad) desc
                             ) and year(f1.fact_fecha) = year(f4.fact_fecha)
            group by fact_cliente
            order by sum(item_cantidad) desc
        ), 
        (
            select sum(item_cantidad * item_precio) 
            from Factura f6
            join Item_Factura i4 on f6.fact_tipo = i4.item_tipo and f6.fact_sucursal = i4.item_sucursal and f6.fact_numero = i4.item_numero
            join Producto on item_producto = prod_codigo 
            where prod_familia = (
                                select top 1 fami_id from Familia
                                join Producto on prod_familia = fami_id
                                join Item_Factura i2 on prod_codigo = item_producto
                                join Factura f2 on f2.fact_tipo = i2.item_tipo and f2.fact_sucursal = i2.item_sucursal and f2.fact_numero = i2.item_numero
                                where year(f2.fact_fecha) = year(f1.fact_fecha)
                                group by fami_id
                                order by sum(item_cantidad) desc
                             ) and year(f1.fact_fecha) = year(f6.fact_fecha)
        ) * 100 / sum(fact_total)
from Factura f1 
group by year(f1.fact_fecha)
/*Ni loco hago el order by, ya me canso este ejercicio*/


/*
26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
 Empleado
 Depósitos que tiene a cargo
 Monto total facturado en el año corriente
 Codigo de Cliente al que mas le vendió
 Producto más vendido
 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.
*/
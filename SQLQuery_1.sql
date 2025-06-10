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

--8.Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
--artículo, stock del depósito que más stock tiene.
select prod_codigo, max(stoc_cantidad) from Producto
join stock on prod_codigo = stoc_producto
GROUP BY prod_codigo
having min(stoc_cantidad) > 0


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
    count(distinct item_producto), max(fact_total)
from Cliente 
join Factura on clie_codigo = fact_cliente
join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where year(fact_fecha) = year(getdate()) - 1
group by clie_codigo
order by count(fact_cliente) desc

/*
16.Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
*/
SELECT 
    c.clie_razon_social, 
    sum(item_cantidad), 
    (   
        SELECT TOP 1 item_producto FROM Factura 
        JOIN Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero 
        WHERE fact_cliente = clie_codigo and YEAR(fact_fecha) = 2012
        GROUP BY item_producto
        ORDER BY sum(item_cantidad) desc, item_producto asc
    ) 
FROM cliente c
JOIN Factura on clie_codigo = fact_cliente
JOIN Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY clie_codigo, clie_razon_social
HAVING sum(fact_total) / 3 > (SELECT TOP 1 SUM(i2.item_cantidad * i2.item_precio)
FROM Item_Factura i2 
JOIN Factura f2 ON
f2.fact_tipo = i2.item_tipo AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_numero = i2.item_numero
WHERE YEAR(f2.fact_fecha) = 2012
GROUP BY i2.item_producto 
ORDER BY SUM(i2.item_cantidad * i2.item_precio) DESC) 


SELECT c.clie_razon_social,
(SELECT SUM(i2.item_cantidad)
FROM factura f2 
JOIN Item_Factura i2 ON
f2.fact_tipo = i2.item_tipo AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_numero = i2.item_numero
WHERE YEAR(f2.fact_fecha) = 2012
AND f2.fact_cliente = c.clie_codigo) unidades,
(SELECT TOP 1 i2.item_producto
FROM factura f2 
JOIN Item_Factura i2 ON
f2.fact_tipo = i2.item_tipo AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_numero = i2.item_numero
WHERE YEAR(f2.fact_fecha) = 2012
AND f2.fact_cliente = c.clie_codigo
GROUP BY i2.item_producto 
ORDER BY SUM(i2.item_cantidad) DESC, item_producto ASC
) producto
FROM Cliente c
INNER JOIN Factura f ON c.clie_codigo = f.fact_cliente 
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY c.clie_codigo, c.clie_razon_social 
HAVING SUM(f.fact_total) / 3 > (SELECT TOP 1 SUM(i2.item_cantidad * i2.item_precio)
FROM Item_Factura i2 
JOIN Factura f2 ON
f2.fact_tipo = i2.item_tipo AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_numero = i2.item_numero
WHERE YEAR(f2.fact_fecha) = 2012
GROUP BY i2.item_producto 
ORDER BY SUM(i2.item_cantidad * i2.item_precio) DESC) 
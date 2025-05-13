create database sport_shop;
go
use sport_shop;
go

create table products
(
    id int primary key identity(1,1) not null,
    name nvarchar(255) not null,
    category nvarchar(50) not null,
    quantity int not null,
    cost_price decimal(10,2) not null,
    manufacturer nvarchar(255) not null,
    sale_price decimal(10,2) not null
);
go

create table employees
(
    id int primary key identity(1,1) not null,
    full_name nvarchar(255) not null,
    position nvarchar(100) not null,
    hire_date date not null,
    gender char(1) not null,
    salary decimal(10,2) not null
);
go

create table customers
(
    id int primary key identity(1,1) not null,
    full_name nvarchar(255) not null,
    email nvarchar(255) not null unique,
    phone nvarchar(20) not null,
    gender char(1) not null,
    total_purchases decimal(10,2) default 0,
    discount_percent int default 0,
    subscribed bit default 0,
    constraint unique_customer unique (full_name, email)
);
go

create table sales
(
    id int primary key identity(1,1) not null,
    product_id int not null,
    sale_price decimal(10,2) not null,
    quantity int not null,
    sale_date datetime default getdate(),
    employee_id int not null,
    customer_id int null,
    foreign key (product_id) references products(id),
    foreign key (employee_id) references employees(id),
    foreign key (customer_id) references customers(id)
);
go

create table history like sales;
go
create table archive like products;
go
create table last_unit like products;
go

create trigger after_sale_insert
    on sales
    for insert
as
begin
insert into history select * from inserted;
end;
go

create trigger after_sale_update
    on products
    for update
            as
begin
    if exists (select 1 from inserted where quantity = 0)
begin
insert into archive select * from products where id in (select id from inserted where quantity = 0);
end;
end;
go

create trigger prevent_duplicate_customer
    on customers
    instead of insert
as
begin
    if exists (select 1 from customers where full_name in (select full_name from inserted) and email in (select email from inserted))
begin
        throw 50000, 'Customer already exists', 1;
end
else
begin
insert into customers select * from inserted;
end;
end;
go

create trigger prevent_customer_deletion
    on customers
    instead of delete
as
begin
    throw 50000, 'Deleting customers is not allowed', 1;
end;
go

create trigger prevent_old_employee_deletion
    on employees
    instead of delete
as
begin
    if exists (select 1 from deleted where hire_date < '2015-01-01')
begin
        throw 50000, 'Cannot delete employees hired before 2015', 1;
end;
end;
go

create trigger update_discount
    on sales
    after insert
as
begin
update customers
set discount_percent = 15
where id in (select customer_id from inserted) and (total_purchases + (select sum(sale_price * quantity) from inserted where customer_id = customers.id)) > 50000;
end;
go

create trigger prevent_specific_brand
    on products
    for insert
as
begin
    if exists (select 1 from inserted where manufacturer = 'Спорт, сонце та штанга')
begin
        throw 50000, 'This manufacturer is not allowed', 1;
end;
end;
go

create trigger check_last_unit
    on products
    for update
            as
begin
    if exists (select 1 from inserted where quantity = 1)
begin
insert into last_unit select * from products where id in (select id from inserted where quantity = 1);
end;
end;
go
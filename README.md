#  Sistema de Caja Offline para Restaurante (Flutter + Drift)

Aplicación móvil desarrollada en Flutter para tablets Android, diseñada para funcionar como una **caja registradora offline**.  
El sistema permite gestionar productos, registrar ventas diarias, controlar gastos y generar reportes sin necesidad de conexión a Internet.  
Todo se almacena localmente usando **SQLite (Drift)**.

---

##  Características principales (MVP actual)

###  Gestión de productos
- Crear productos con precio **incluyendo IVA (15%)**  
- Editar productos  
- Eliminar productos  
- Visualización tipo tarjeta (Cards)

###  Caja (Registro de ventas)
- Agregar productos al pedido (sumar/restar cantidades)  
- Ver desglose:
  - Subtotal sin IVA  
  - IVA calculado  
  - Total  
- Registrar venta con o sin nombre del cliente  
- Registrar venta con o sin impresión (pendiente integración con impresora)

###  Pedidos del día
- Listado completo de ventas del día  
- Editable (Pendiente)
- Se limpia automáticamente al **cerrar caja**

###  Totales del día (KPIs)
- Subtotal acumulado  
- IVA acumulado  
- Total del día  
- Cantidad de productos vendidos  
- **Producto más vendido (histórico: no se borra con cierre de caja)**

###  Gastos (Pendiente)
- Registrar gastos variáveis (descripción + valor)  
- Listado de gastos diarios  
- Total de gastos del día  
- Se limpia al cerrar caja

###  Cierre de caja
- Limpia:
  - Ventas del día  
  - Pedidos del día  
  - Gastos  
  - KPIs diarios  
- Genera resumen del día  
- No elimina el ítem más vendido histórico

---

##  Tecnologías utilizadas

- **Flutter 3.x**  
- **Dart**  
- **SQLite + Drift ORM**  
- **Riverpod** (estado global)  
- **GoRouter** (navegación)  
- Arquitectura modular  
- Funciona 100% offline

---

##  Requisitos para ejecutar el proyecto

### Necesitas instalar:
1. Flutter  
2. Android Studio o VS Code  
3. Dart SDK (incluido en Flutter)  
4. Un dispositivo Android o tablet

---

##  Cómo ejecutar el proyecto

```bash
git clone https://github.com/LastDaniels/Registrapp.git
cd (en la carpeta donde hayas puesto el proyecto)
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

##  Cómo generar la APK

```bash
flutter build apk --release
```

La APK aparecerá en:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

##  Release actual

Descargar versión estable: **[Release v0.1.0](https://github.com/LastDaniels/Registrapp/releases/tag/v0.1.0)**

---

## 📈 Roadmap 

- Integración con impresora térmica Bluetooth/USB  
- Reportes por rango de fechas  (opcional)
- Exportación a PDF/Excel  (opcional)
- Multiusuario  (opcional)
- KPI adicionales (opcional)

---

## ✨ Créditos

Desarrollado por: **Daniel Picon / Guido Flores / Pratt Garcia / Michael Jimenez**  
Materia: Ingeniería de Software 2

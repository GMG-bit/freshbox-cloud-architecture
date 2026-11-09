// ==============================================================================
// FreshBox SpA - Frontend App (S3 Static Hosting)
// Integracion Frontend a Fachada API Gateway (EKS CRUD + Serverless Lambdas)
// ==============================================================================

const USER_ID = "user001";
let API_BASE_URL = localStorage.getItem("FRESHBOX_API_URL") || "";

// Productos locales de respaldo si la API no esta disponible
const FALLBACK_PRODUCTS = [
    { id: 1, nombre: "Manzana organica 1kg", descripcion: "Cultivo sin pesticidas, bolsa 1kg", precio: 3490, categoria: "Frutas" },
    { id: 2, nombre: "Lechuga hidroponica", descripcion: "Fresca en sistema hidroponico", precio: 1990, categoria: "Verduras" },
    { id: 3, nombre: "Granola artesanal 500g", descripcion: "Avena, miel y almendras sin azucar", precio: 4990, categoria: "Snacks" },
    { id: 4, nombre: "Jugo natural naranja 1L", descripcion: "100% natural, sin colorantes", precio: 2990, categoria: "Bebidas" },
    { id: 5, nombre: "Mix frutos secos 250g", descripcion: "Nueces, almendras y pasas organicas", precio: 5490, categoria: "Snacks" }
];

document.addEventListener("DOMContentLoaded", () => {
    const input = document.getElementById("api-url");
    if (input && API_BASE_URL) {
        input.value = API_BASE_URL;
    }
    loadProducts();
    refreshCart();
});

function saveApiUrl() {
    const input = document.getElementById("api-url");
    API_BASE_URL = input.value.trim().replace(/\/$/, "");
    localStorage.setItem("FRESHBOX_API_URL", API_BASE_URL);
    alert("URL de API Gateway guardada correctamente.");
    loadProducts();
    refreshCart();
}

async function loadProducts() {
    const grid = document.getElementById("products-grid");
    grid.innerHTML = '<div class="loading">Consultando microservicio get-products en EKS...</div>';
    
    if (!API_BASE_URL) {
        renderProducts(FALLBACK_PRODUCTS);
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/products`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        const products = Array.isArray(data) ? data : (data.products || FALLBACK_PRODUCTS);
        renderProducts(products);
    } catch (err) {
        console.warn("Fallo al conectar con EKS. Mostrando productos locales:", err);
        renderProducts(FALLBACK_PRODUCTS);
    }
}

function renderProducts(products) {
    const grid = document.getElementById("products-grid");
    grid.innerHTML = "";
    
    products.forEach(p => {
        const card = document.createElement("div");
        card.className = "product-card";
        card.innerHTML = `
            <h4>${p.nombre}</h4>
            <p>${p.descripcion || "Producto fresco organico certificado."}</p>
            <div class="product-footer">
                <span class="price">$${Number(p.precio).toLocaleString("es-CL")} CLP</span>
                <button class="btn-add" onclick="addToCart('${p.id}', '${p.nombre}', ${p.precio})">Agregar +</button>
            </div>
        `;
        grid.appendChild(card);
    });
}

async function addToCart(productId, nombre, precio) {
    if (!API_BASE_URL) {
        alert(`Producto [${nombre}] agregado (Simulado local). Configura la URL del API Gateway para persistir en DynamoDB.`);
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/cart`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                userId: USER_ID,
                productId: productId,
                nombre: nombre,
                precio: precio,
                cantidad: 1
            })
        });
        if (response.ok) {
            refreshCart();
        } else {
            console.error("Error al agregar al carrito en DynamoDB");
        }
    } catch (err) {
        console.error("Error de conexion con Lambda cart-function:", err);
    }
}

async function refreshCart() {
    if (!API_BASE_URL) return;

    try {
        const response = await fetch(`${API_BASE_URL}/api/cart?userId=${USER_ID}`);
        if (!response.ok) return;
        const data = await response.json();
        
        const countBadge = document.getElementById("cart-count");
        const itemsContainer = document.getElementById("cart-items");
        const totalSpan = document.getElementById("cart-total");
        
        const items = data.items || [];
        countBadge.innerText = items.length;
        
        if (items.length === 0) {
            itemsContainer.innerHTML = '<p class="empty-cart">El carrito está vacío</p>';
            totalSpan.innerText = '$0 CLP';
            return;
        }

        itemsContainer.innerHTML = "";
        items.forEach(item => {
            const row = document.createElement("div");
            row.className = "cart-item";
            row.innerHTML = `
                <div>
                    <strong>${item.nombre}</strong><br>
                    <small>Cant: ${item.cantidad} x $${Number(item.precio).toLocaleString("es-CL")}</small>
                </div>
                <button onclick="removeFromCart('${item.productId}')" style="background:none;border:none;cursor:pointer;color:#e53e3e;">✕</button>
            `;
            itemsContainer.appendChild(row);
        });

        totalSpan.innerText = `$${Number(data.total || 0).toLocaleString("es-CL")} CLP`;

    } catch (err) {
        console.warn("No fue posible actualizar el carrito:", err);
    }
}

async function removeFromCart(productId) {
    if (!API_BASE_URL) return;
    try {
        await fetch(`${API_BASE_URL}/api/cart/${productId}?userId=${USER_ID}`, { method: "DELETE" });
        refreshCart();
    } catch (err) {
        console.error("Error al eliminar item del carrito:", err);
    }
}

async function placeOrder() {
    const statusDiv = document.getElementById("order-status");
    statusDiv.className = "order-status";
    statusDiv.innerText = "Enviando orden a cola Amazon SQS...";
    statusDiv.style.display = "block";

    if (!API_BASE_URL) {
        statusDiv.className = "order-status success";
        statusDiv.innerText = "¡Pedido recibido! (Modo Simulación: ORD-TEST1234)";
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/orders`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ userId: USER_ID })
        });
        
        const result = await response.json();
        if (response.ok || response.status === 202) {
            statusDiv.className = "order-status success";
            statusDiv.innerHTML = `
                <strong>¡Pedido Confirmado!</strong><br>
                ${result.message}<br>
                ID de Orden: <code>${result.orderId}</code><br>
                <small>Procesamiento asíncrono en curso en RDS MySQL Multi-AZ.</small>
            `;
            setTimeout(() => { refreshCart(); }, 2500);
        } else {
            statusDiv.innerText = "Error: " + (result.error || "No se pudo procesar la orden.");
        }
    } catch (err) {
        statusDiv.innerText = "Fallo de conexión al enviar orden: " + err.message;
    }
}

function toggleCart() {
    const modal = document.getElementById("cart-modal");
    modal.style.display = (modal.style.display === "block") ? "none" : "block";
}

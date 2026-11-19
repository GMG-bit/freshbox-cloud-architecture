import os
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

def create_presentation_ep3(output_path):
    prs = Presentation()
    prs.slide_width = Inches(13.333) # 16:9 Widescreen
    prs.slide_height = Inches(7.5)
    blank_layout = prs.slide_layouts[6]

    # Duoc UC Corporate Palette
    C_NAVY = RGBColor(0, 43, 73)      # #002B49
    C_ORANGE = RGBColor(227, 108, 10) # #E36C0A
    C_DARK = RGBColor(30, 41, 59)     # #1E293B
    C_LIGHT = RGBColor(241, 245, 249) # #F1F5F9
    C_WHITE = RGBColor(255, 255, 255)
    C_GRAY = RGBColor(100, 116, 139)  # #64748B
    C_ACCENT_BLUE = RGBColor(14, 116, 144)

    def add_header(slide, title_text, category_text="EVALUACIÓN PARCIAL 3 (EP3) • ARQUITECTURA CLOUD (ARY1102)"):
        # Header background bar
        hdr_box = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(1.15))
        hdr_box.fill.solid()
        hdr_box.fill.fore_color.rgb = C_NAVY
        hdr_box.line.color.rgb = C_NAVY

        # Category
        cat_p = slide.shapes.add_textbox(Inches(0.8), Inches(0.12), Inches(11.7), Inches(0.3)).text_frame.paragraphs[0]
        c_run = cat_p.add_run()
        c_run.text = category_text.upper()
        c_run.font.size = Pt(9.5)
        c_run.font.bold = True
        c_run.font.color.rgb = C_ORANGE

        # Title
        t_p = slide.shapes.add_textbox(Inches(0.8), Inches(0.4), Inches(11.7), Inches(0.6)).text_frame.paragraphs[0]
        t_run = t_p.add_run()
        t_run.text = title_text
        t_run.font.size = Pt(20)
        t_run.font.bold = True
        t_run.font.color.rgb = C_WHITE

        # Footer line
        ftr_p = slide.shapes.add_textbox(Inches(0.8), Inches(7.05), Inches(11.7), Inches(0.35)).text_frame.paragraphs[0]
        ftr_p.text = "FreshBox SpA • Modernización Serverless Híbrida (EKS + Lambda + SQS + DynamoDB) • Duoc UC 2026"
        ftr_p.font.size = Pt(9)
        ftr_p.font.color.rgb = C_GRAY

    # --- SLIDE 1: PORTADA ---
    s1 = prs.slides.add_slide(blank_layout)
    bg = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0), Inches(0), Inches(13.333), Inches(7.5))
    bg.fill.solid()
    bg.fill.fore_color.rgb = C_NAVY
    bg.line.color.rgb = C_NAVY

    tb1 = s1.shapes.add_textbox(Inches(1.0), Inches(1.2), Inches(11.3), Inches(1.0))
    p = tb1.text_frame.paragraphs[0]
    r = p.add_run()
    r.text = "DUOC UC • ESCUELA DE INFORMÁTICA Y TELECOMUNICACIONES"
    r.font.size = Pt(14)
    r.font.bold = True
    r.font.color.rgb = C_ORANGE

    p2 = tb1.text_frame.add_paragraph()
    p2.space_before = Pt(15)
    r2 = p2.add_run()
    r2.text = "FreshBox SpA: Modernización hacia Arquitectura Híbrida Serverless"
    r2.font.size = Pt(28)
    r2.font.bold = True
    r2.font.color.rgb = C_WHITE

    p3 = tb1.text_frame.add_paragraph()
    p3.space_before = Pt(10)
    r3 = p3.add_run()
    r3.text = "Desacoplamiento Asíncrono con Amazon SQS, Persistencia NoSQL con DynamoDB TTL, FaaS con AWS Lambda y Frontend en Amazon S3"
    r3.font.size = Pt(14)
    r3.font.color.rgb = RGBColor(203, 213, 225)

    # Metadata card
    card = s1.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(1.0), Inches(4.5), Inches(11.3), Inches(2.2))
    card.fill.solid()
    card.fill.fore_color.rgb = RGBColor(15, 30, 50)
    card.line.color.rgb = C_ORANGE
    
    ctb = s1.shapes.add_textbox(Inches(1.3), Inches(4.7), Inches(10.7), Inches(1.8))
    cp1 = ctb.text_frame.paragraphs[0]
    cp1.text = "DATOS DE LA EVALUACIÓN Y DEFENSA TÉCNICA:"
    cp1.font.bold = True
    cp1.font.size = Pt(11)
    cp1.font.color.rgb = C_ORANGE

    cp2 = ctb.text_frame.add_paragraph()
    cp2.space_before = Pt(8)
    cp2.text = "• Estudiante: Gaston Mardones González   |   Asignatura: Arquitectura Cloud (ARY1102) - Ponderación: 30%\n• Entorno de Ejecución: AWS Academy Learner Lab (EKS + RDS Multi-AZ + Serverless)\n• Docente Diseñador: Ignacio A. Pastenet M.   |   Fecha: Noviembre 2026   |   Tiempo Asignado: 10 Minutos"
    cp2.font.size = Pt(11)
    cp2.font.color.rgb = C_WHITE

    # Helper function for 2-column cards
    def add_two_column_cards(slide, left_title, left_points, right_title, right_points):
        # Left card
        card_l = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(1.5), Inches(5.6), Inches(5.3))
        card_l.fill.solid()
        card_l.fill.fore_color.rgb = C_LIGHT
        card_l.line.color.rgb = RGBColor(203, 213, 225)

        tb_l = slide.shapes.add_textbox(Inches(1.1), Inches(1.7), Inches(5.0), Inches(4.8))
        p_lt = tb_l.text_frame.paragraphs[0]
        p_lt.text = left_title
        p_lt.font.bold = True
        p_lt.font.size = Pt(15)
        p_lt.font.color.rgb = C_NAVY

        for pt in left_points:
            p_lp = tb_l.text_frame.add_paragraph()
            p_lp.space_before = Pt(10)
            p_lp.text = "• " + pt
            p_lp.font.size = Pt(11)
            p_lp.font.color.rgb = C_DARK

        # Right card
        card_r = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(6.9), Inches(1.5), Inches(5.6), Inches(5.3))
        card_r.fill.solid()
        card_r.fill.fore_color.rgb = C_LIGHT
        card_r.line.color.rgb = RGBColor(203, 213, 225)

        tb_r = slide.shapes.add_textbox(Inches(7.2), Inches(1.7), Inches(5.0), Inches(4.8))
        p_rt = tb_r.text_frame.paragraphs[0]
        p_rt.text = right_title
        p_rt.font.bold = True
        p_rt.font.size = Pt(15)
        p_rt.font.color.rgb = C_ORANGE

        for pt in right_points:
            p_rp = tb_r.text_frame.add_paragraph()
            p_rp.space_before = Pt(10)
            p_rp.text = "• " + pt
            p_rp.font.size = Pt(11)
            p_rp.font.color.rgb = C_DARK

    # --- SLIDE 2: DIAGNÓSTICO Y DESAFÍOS ---
    s2 = prs.slides.add_slide(blank_layout)
    add_header(s2, "Diagnóstico del Caso: De EKS Base (EP2) hacia Modelo Híbrido (EP3)")
    add_two_column_cards(
        s2,
        "Diagnóstico de Arquitectura Base (EP2)",
        [
            "Frontend Contenerizado Ocioso: Pod Nginx corriendo 24/7 en worker nodes EC2 para servir HTML/CSS/JS estático, consumiendo RAM y CPU.",
            "Acoplamiento Fuerte en Checkout: Confirmación de órdenes sincrónica directa hacia MySQL RDS; riesgo crítico de agotar el pool de conexiones.",
            "Carritos Huérfanos Ineficientes: Almacenar compras inconclusas en BD relacional exige scripts cron de limpieza con alto I/O.",
            "Costos Fijos en Horarios Valle: Pagar por instancias y pods en la madrugada cuando el tráfico de compras es prácticamente nulo."
        ],
        "Objetivos Estratégicos de Negocio (EP3)",
        [
            "Venta Directa al Consumidor: Implementar Carrito interactivo, cálculo de total y confirmación formal de órdenes ('Su pedido fue recibido').",
            "Desacoplamiento con Amazon SQS: Amortiguar ráfagas transaccionales durante CyberDays; cero pedidos perdidos por saturación.",
            "Persistencia NoSQL con TTL: DynamoDB On-Demand con autolimpieza de carritos a las 24 horas sin costo operacional.",
            "Frontend en Amazon S3 Static Hosting: Reducción drástica del costo web a centavos y liberación de recursos en el clúster EKS."
        ]
    )

    # --- SLIDE 3: ARQUITECTURA TO-BE ---
    s3 = prs.slides.add_slide(blank_layout)
    add_header(s3, "Arquitectura TO-BE Híbrida: Desacoplamiento y 14 Componentes Cloud")
    add_two_column_cards(
        s3,
        "Capa Frontend y API Gateway",
        [
            "1. Amazon S3: Static Website Hosting para la SPA (HTML5/CSS/JS). Cero servidores web que administrar.",
            "2. Amazon API Gateway: Fachada REST pública única (HTTP API v2) con CORS habilitado y stage 'prod'.",
            "Ruteo Inteligente (8 Rutas): Enruta peticiones CRUD de productos hacia EKS y checkout/carrito hacia AWS Lambda.",
            "Protección DoS y Rate Limiting: API Gateway gestiona la contrapresión y mitiga abusos antes de llegar al backend."
        ],
        "Separación de Responsabilidades Backend",
        [
            "Dominio EKS (PaaS): 4 microservicios Node.js (get, create, update, delete) sobre worker nodes t4g.small con Ingress ALB y HPA.",
            "Dominio Serverless (FaaS): 3 funciones Lambda Node.js 20.x (procesar-carrito, crear-orden, procesar-orden).",
            "Amazon DynamoDB: Carrito temporal On-Demand con TTL nativo de 24 horas (expiresAt).",
            "Amazon SQS + DLQ: Cola desacoplada con Dead Letter Queue tras 3 reintentos fallidos, persistiendo en MySQL RDS Multi-AZ."
        ]
    )

    # --- SLIDE 4: DESACOPLAMIENTO ASÍNCRONO ---
    s4 = prs.slides.add_slide(blank_layout)
    add_header(s4, "Desacoplamiento Asíncrono: Amazon SQS y Resiliencia Transaccional")
    add_two_column_cards(
        s4,
        "Flujo del Productor (Lambda crear-orden)",
        [
            "1. Cliente presiona 'Confirmar Pedido' en la SPA de S3.",
            "2. API Gateway invoca síncronamente a 'freshbox-crear-orden'.",
            "3. La Lambda consulta los ítems en DynamoDB y calcula el total.",
            "4. Publica el mensaje JSON en la cola SQS 'ordenes-freshbox'.",
            "5. Respuesta inmediata (< 90 ms) al usuario con HTTP 200 y número de orden (ORD-XXXXX).",
            "Resultado: El cliente nunca queda bloqueado esperando bloqueos de base de datos."
        ],
        "Flujo del Consumidor (Lambda procesar-orden) y DLQ",
        [
            "1. Amazon SQS dispara la Lambda 'freshbox-procesar-orden' mediante Event Source Mapping en lotes de hasta 10 mensajes.",
            "2. La Lambda (en VPC privada) inserta el pedido en la tabla 'ordenes' de Amazon RDS MySQL Multi-AZ.",
            "3. Se ejecuta BatchWriteCommand en DynamoDB para limpiar el carrito.",
            "4. Dead Letter Queue (DLQ): Si la base de datos se satura, el mensaje se reintenta 3 veces (maxReceiveCount=3) y se traslada a la DLQ sin perder datos."
        ]
    )

    # --- SLIDE 5: DYNAMODB CON TTL ---
    s5 = prs.slides.add_slide(blank_layout)
    add_header(s5, "Persistencia NoSQL: DynamoDB con TTL para Carritos Temporales")
    add_two_column_cards(
        s5,
        "Diseño de Tabla NoSQL (carrito-freshbox)",
        [
            "Modelo de Datos: Clave-Valor optimizado para latencias < 5 ms.",
            "Partition Key (PK): 'userId' (String) para agrupar todas las compras del usuario.",
            "Sort Key (SK): 'productId' (String) para identificar unívocamente cada producto agregado.",
            "Modo de Facturación: On-Demand (PAY_PER_REQUEST); cero costo en ausencia de transacciones.",
            "Escalamiento automático transparente sin particionamiento manual."
        ],
        "Mecanismo de Expiración TTL (Time To Live)",
        [
            "Atributo TTL: 'expiresAt' (Entero UNIX Epoch).",
            "Cálculo: Timestamp actual + 86.400 segundos (24 horas).",
            "Autolimpieza Nativa: DynamoDB purga automáticamente los carritos expirados en segundo plano.",
            "Ventaja Operacional: Cero consumo de RCU/WCU y erradicación de scripts cron en servidores que degradan la base de datos."
        ]
    )

    # --- SLIDE 6: SEGURIDAD Y REDES ---
    s6 = prs.slides.add_slide(blank_layout)
    add_header(s6, "Seguridad en Profundidad y Conectividad Privada (VPC Endpoints)")
    add_two_column_cards(
        s6,
        "Matriz de Seguridad y Roles IAM",
        [
            "Rol Unificado LabRole: Cumple las políticas estrictas de AWS Academy Learner Lab con mínimo privilegio para Lambda, EKS y CloudWatch.",
            "Security Groups en Capas: RDS MySQL (3306) solo acepta conexiones desde worker nodes EKS y desde la Lambda de procesamiento.",
            "ALB Security Group: Expone puertos 80/443 a Internet y restringe acceso directo a los nodos Kubernetes.",
            "Cifrado en Reposo: Volúmenes EBS, instancias RDS MySQL y colas SQS protegidos con cifrado KMS / SSE administrado."
        ],
        "VPC Gateway Endpoints (DynamoDB y S3)",
        [
            "Enrutamiento Privado: Tablas de ruteo configuradas con prefijos de servicio (pl-*) para DynamoDB y S3.",
            "Ahorro Financiero: Tráfico interno sin costo de transferencia de NAT Gateway ($0,045 USD/GB).",
            "Latencia Optimizada: Comunicación por la red troncal interna de AWS (reducción del 35% en tiempos de viaje).",
            "Aislamiento Perimetral: La comunicación entre Lambda en VPC y DynamoDB nunca sale a la Internet pública."
        ]
    )

    # --- SLIDE 7: GUÍA DEMO EN VIVO ---
    s7 = prs.slides.add_slide(blank_layout)
    add_header(s7, "Guía de la Demostración en Vivo en AWS Learner Lab (10 Minutos)")
    add_two_column_cards(
        s7,
        "Puntos Clave a Mostrar en Consola AWS (5 Min)",
        [
            "1. Amazon S3: Bucket con Static Website Hosting activo y archivos index.html, styles.css, app.js cargados.",
            "2. Amazon API Gateway: API 'freshbox-api' con las 8 rutas operativas (CRUD productos, carrito, órdenes) y CORS habilitado.",
            "3. AWS Lambda: 3 funciones Node.js 20.x operativas con rol LabRole y trigger SQS activo.",
            "4. Amazon DynamoDB: Tabla 'carrito-freshbox' con TTL habilitado sobre expiresAt.",
            "5. Amazon SQS: Cola 'ordenes-freshbox' y DLQ vinculada con política de reintento.",
            "6. Amazon EKS: 4 pods CRUD en estado Running y HPA sobre get-products."
        ],
        "Validación Funcional End-to-End (5 Min)",
        [
            "1. Abrir la URL del sitio estático en S3 en el navegador.",
            "2. Verificar la carga del catálogo desde EKS a través de API Gateway.",
            "3. Agregar productos al carrito y verificar la inserción en DynamoDB.",
            "4. Presionar 'Confirmar Pedido' y constatar la confirmación instantánea.",
            "5. Mostrar el mensaje encolado en SQS y consumido por la Lambda.",
            "6. Ejecutar SELECT en MySQL RDS demostrando el registro en la tabla 'ordenes'.",
            "7. Constatar la autolimpieza del carrito en DynamoDB."
        ]
    )

    # --- SLIDE 8: RESULTADOS Y CONCLUSIONES ---
    s8 = prs.slides.add_slide(blank_layout)
    add_header(s8, "Evaluación Financiera, Conclusiones y Próximos Pasos")
    add_two_column_cards(
        s8,
        "Optimización de Costos y Eficiencia",
        [
            "Ahorro Proyectado: Reducción del 45% al 60% en costos directos de cómputo al eliminar pods ociosos en EKS.",
            "Frontend en S3: Costo mensual inferior a $0,20 USD frente a $14,50 USD por pod en Kubernetes.",
            "DynamoDB + Lambda: Facturación cero en horas valle nocturnas mediante pago por uso.",
            "Observabilidad CloudWatch: Trazabilidad completa de peticiones, tiempos de respuesta y errores."
        ],
        "Conclusiones y Recomendaciones Técnicas",
        [
            "Coexistencia Estratégica: El modelo híbrido capitaliza la inversión en EKS para el catálogo estable y usa Serverless para la volatilidad comercial.",
            "Resiliencia a Prueba de CyberDays: Amazon SQS absorbe picos sin saturar las conexiones de MySQL RDS Multi-AZ.",
            "Próximos Pasos (Producción): Incorporar CloudFront como CDN perimetral global y AWS WAF para mitigación de ataques web y bots."
        ]
    )

    prs.save(output_path)
    print(f"Presentation saved successfully at: {output_path}")

if __name__ == '__main__':
    pptx_file = r'G:\Duoc\Semestre VI\Arquitecto Cloud y Diseño de Soluciones en La Nube\EVA1\freshbox-cloud-architecture\docs\Presentacion_EP3_FreshBox.pptx'
    create_presentation_ep3(pptx_file)

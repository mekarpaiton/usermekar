import requests, json, os
from jinja2 import Template

# Ambil data produk dari API ente
res = requests.get('https://abahkhuzai.pythonanywhere.com/api/produk')
produk = res.json()

# Template HTML katalog
html_template = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Katalog TB. MEKAR</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body{font-family:sans-serif;margin:0;background:#f5f5f5}
        .header{background:#7F00FF;color:white;padding:20px;text-align:center}
        .produk{display:flex;background:white;margin:10px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
        .produk img{width:100px;height:100px;object-fit:cover}
        .info{padding:12px;flex:1}
        .harga{color:#7F00FF;font-weight:bold;font-size:18px}
        .stok{color:white;padding:2px 8px;border-radius:12px;font-size:12px}
        .stok.ada{background:green}
        .stok.sedikit{background:orange}
        .stok.habis{background:red}
    </style>
</head>
<body>
    <div class="header">
        <h1>TB. MEKAR</h1>
        <p>Katalog Terbaru</p>
    </div>
    {% for p in produk %}
    <div class="produk">
        <img src="{{ p.foto }}" alt="{{ p.nama }}">
        <div class="info">
            <h3>{{ p.nama }}</h3>
            <div class="harga">Rp {{ p.harga.values()|first }} / {{ p.satuan }}</div>
            <span class="stok {% if p.stok > 10 %}ada{% elif p.stok > 0 %}sedikit{% else %}habis{% endif %}">
                Stok: {{ p.stok }}
            </span>
        </div>
    </div>
    {% endfor %}
</body>
</html>
'''

# Generate file
os.makedirs('public', exist_ok=True)
with open('public/katalog.html', 'w') as f:
    template = Template(html_template)
    f.write(template.render(produk=produk))

print("katalog.html berhasil di-generate")
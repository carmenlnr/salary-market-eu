# src/recogida.py
# Funciones para la recogida de datos desde la API de Adzuna

import requests
import time


def recoger_ofertas(app_id, app_key, pais, categoria, n_paginas=8, por_pagina=50):
    """
    Recoge ofertas de empleo de un país y categoría desde la API de Adzuna.
    Devuelve una lista de diccionarios con las variables seleccionadas.
    """
    ofertas = []

    for pagina in range(1, n_paginas + 1):
        url = f"https://api.adzuna.com/v1/api/jobs/{pais}/search/{pagina}"
        params = {
            "app_id": app_id,
            "app_key": app_key,
            "results_per_page": por_pagina,
            "category": categoria
        }

        respuesta = requests.get(url, params=params)

        if respuesta.status_code != 200:
            print(f"  Error {respuesta.status_code} en {pais}/{categoria} pág {pagina}")
            break

        resultados = respuesta.json()["results"]

        if len(resultados) == 0:
            break

        for oferta in resultados:
            ofertas.append({
                "title": oferta.get("title"),
                "category": oferta.get("category", {}).get("label"),
                "salary_min": oferta.get("salary_min"),
                "salary_max": oferta.get("salary_max"),
                "salary_is_predicted": oferta.get("salary_is_predicted"),
                "location": oferta.get("location", {}).get("display_name"),
                "company": oferta.get("company", {}).get("display_name"),
                "contract_type": oferta.get("contract_type"),
                "created": oferta.get("created"),
                "pais": pais
            })

        time.sleep(1)

    return ofertas


def recoger_historico(app_id, app_key, pais, categoria):
    """
    Recoge la evolución del salario medio mensual de un país y categoría.
    Devuelve una lista de diccionarios: {pais, categoria, mes, salario_medio}.
    """
    url = f"https://api.adzuna.com/v1/api/jobs/{pais}/history"
    params = {
        "app_id": app_id,
        "app_key": app_key,
        "category": categoria
    }

    respuesta = requests.get(url, params=params)

    if respuesta.status_code != 200:
        print(f"  Error {respuesta.status_code} en {pais}/{categoria}")
        return []

    meses = respuesta.json().get("month", {})

    filas = []
    for mes, salario in meses.items():
        filas.append({
            "pais": pais,
            "categoria": categoria,
            "mes": mes,
            "salario_medio": salario
        })

    return filas
import json

crs_data = {
    "type": "CRS",
    "properties": {
        "name": "Lambert_Conformal_Conic",
        "wkt": """
        PROJCRS["Lambert_Conformal_Conic",
            BASEGEOGCRS["WGS 84",
                DATUM["WGS_1984",
                    ELLIPSOID["Sphere", 6371229, 0,
                        LENGTHUNIT["metre", 1,
                            ID["EPSG", 9001]
                        ]
                    ]
                ],
                PRIMEM["Greenwich", 0,
                    ANGLEUNIT["degree", 0.0174532925199433,
                        ID["EPSG", 9122]
                    ]
                ]
            ],
            CONVERSION["unnamed",
                METHOD["Lambert Conic Conformal (1SP)",
                    ID["EPSG", 9801]
                ],
                PARAMETER["Latitude of natural origin", 63,
                    ANGLEUNIT["degree", 0.0174532925199433],
                    ID["EPSG", 8801]
                ],
                PARAMETER["Longitude of natural origin", 15,
                    ANGLEUNIT["degree", 0.0174532925199433],
                    ID["EPSG", 8802]
                ],
                PARAMETER["Scale factor at natural origin", 1,
                    SCALEUNIT["unity", 1],
                    ID["EPSG", 8805]
                ],
                PARAMETER["False easting", 0,
                    LENGTHUNIT["metre", 1],
                    ID["EPSG", 8806]
                ],
                PARAMETER["False northing", 0,
                    LENGTHUNIT["metre", 1],
                    ID["EPSG", 8807]
                ],
                PARAMETER["Standard parallel", 63,
                    ANGLEUNIT["degree", 0.0174532925199433],
                    ID["EPSG", 9122]
                ]
            ],
            CS[Cartesian, 2],
            AXIS["easting", east,
                ORDER[1],
                LENGTHUNIT["metre", 1,
                    ID["EPSG", 9001]
                ]
            ],
            AXIS["northing", north,
                ORDER[2],
                LENGTHUNIT["metre", 1,
                    ID["EPSG", 9001]
                ]
            ]
        ]
        """
    }
}

# Write the CRS data to a .json file
with open('crs.json', 'w') as file:
    json.dump(crs_data, file, indent=4)



import json

def read_crs_json(file_path):
    """Read the CRS data from a JSON file."""
    with open(file_path, 'r') as file:
        crs_data = json.load(file)
    return crs_data['properties']['wkt']

# Example usage
crs_json_file = 'crs.json'
crs_wkt = read_crs_json(crs_json_file)
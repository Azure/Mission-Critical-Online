{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 10,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# Global",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 11,
            "y": 0,
            "colSpan": 10,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# Regional ${stamp_label}",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "2": {
          "position": {
            "x": 22,
            "y": 0,
            "colSpan": 8,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# Application",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "3": {
          "position": {
            "x": 0,
            "y": 1,
            "colSpan": 5,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## [Front Door](https://portal.azure.com/#@${tenant_id}/resource${front_door_id})",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "4": {
          "position": {
            "x": 5,
            "y": 1,
            "colSpan": 5,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## [Cosmos DB](https://portal.azure.com/#@${tenant_id}/resource${cosmosdb_id})",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "5": {
          "position": {
            "x": 11,
            "y": 1,
            "colSpan": 10,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## Event Hubs",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "6": {
          "position": {
            "x": 22,
            "y": 1,
            "colSpan": 4,
            "rowSpan": 2
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${stamp_appi_id_0}"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/AllWebTestsResponseTimeFullGalleryAdapterPart",
            "isAdapter": true,
            "asset": {
              "idInputName": "ComponentId",
              "type": "ApplicationInsights"
            },
            "savedContainerState": {
              "partTitle": "${stamp_location_0} - Availability tests",
              "assetName": "${stamp_appi_name_0} - 24 hours"
            }
          }
        },
        "7": {
          "position": {
            "x": 26,
            "y": 1,
            "colSpan": 4,
            "rowSpan": 2
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${stamp_appi_id_1}"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/AllWebTestsResponseTimeFullGalleryAdapterPart",
            "isAdapter": true,
            "asset": {
              "idInputName": "ComponentId",
              "type": "ApplicationInsights"
            },
            "savedContainerState": {
              "partTitle": "${stamp_location_1} - Availability tests",
              "assetName": "${stamp_appi_name_1} - 24 hours"
            }
          }
        },
        "8": {
          "position": {
            "x": 0,
            "y": 2,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "RequestCount",
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Request Count",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Request count",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "RequestCount",
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Request Count",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Request count",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                }
              }
            }
          }
        },
        "9": {
          "position": {
            "x": 5,
            "y": 2,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "ProvisionedThroughput",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Provisioned Throughput"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "AutoscaleMaxThroughput",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Autoscale Max Throughput"
                        }
                      }
                    ],
                    "title": "Provisioned vs. autoscale throughtput",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "ProvisionedThroughput",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Provisioned Throughput"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "AutoscaleMaxThroughput",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Autoscale Max Throughput"
                        }
                      }
                    ],
                    "title": "Provisioned vs. autoscale throughtput",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "10": {
          "position": {
            "x": 11,
            "y": 2,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_0}"
                        },
                        "name": "IncomingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Incoming Messages"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_0}"
                        },
                        "name": "OutgoingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Outgoing Messages"
                        }
                      }
                    ],
                    "title": "${stamp_location_0} - Incoming/Outgoing messages",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_0}"
                        },
                        "name": "IncomingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Incoming Messages"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_0}"
                        },
                        "name": "OutgoingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Outgoing Messages"
                        }
                      }
                    ],
                    "title": "${stamp_location_0} - Incoming/Outgoing messages",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "11": {
          "position": {
            "x": 16,
            "y": 2,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_1}"
                        },
                        "name": "IncomingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Incoming Messages"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_1}"
                        },
                        "name": "OutgoingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Outgoing Messages"
                        }
                      }
                    ],
                    "title": "${stamp_location_1} - Incoming/Outgoing messages",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_1}"
                        },
                        "name": "IncomingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Incoming Messages"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_eventhub_id_1}"
                        },
                        "name": "OutgoingMessages",
                        "aggregationType": 1,
                        "namespace": "microsoft.eventhub/namespaces",
                        "metricVisualization": {
                          "displayName": "Outgoing Messages"
                        }
                      }
                    ],
                    "title": "${stamp_location_1} - Incoming/Outgoing messages",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        },
        "12": {
          "position": {
            "x": 22,
            "y": 3,
            "colSpan": 8,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_appi_id_0}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 7,
                        "namespace": "microsoft.insights/components",
                        "metricVisualization": {
                          "displayName": "${stamp_location_0} - Failed requests",
                          "resourceDisplayName": "${stamp_appi_name_0}",
                          "color": "#EC008C"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_appi_id_1}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 7,
                        "namespace": "microsoft.insights/components",
                        "metricVisualization": {
                          "displayName": "${stamp_location_1} - Failed requests",
                          "resourceDisplayName": "${stamp_appi_name_1}",
                          "color": "#EC558C"
                        }
                      }
                    ],
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 3
                    },
                    "openBladeOnClick": {
                      "openBlade": true,
                      "destinationBlade": {
                        "bladeName": "ResourceMenuBlade",
                        "parameters": {
                          "id": "${stamp_appi_id_0}",
                          "menuid": "failures"
                        },
                        "extensionName": "HubsExtension",
                        "options": {
                          "parameters": {
                            "id": "${stamp_appi_id_0}",
                            "menuid": "failures"
                          }
                        }
                      }
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_appi_id_0}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 7,
                        "namespace": "microsoft.insights/components",
                        "metricVisualization": {
                          "displayName": "${stamp_location_0} - Failed requests",
                          "resourceDisplayName": "${stamp_appi_name_0}",
                          "color": "#EE008C"
                        }
                      },
                      {
                        "resourceMetadata": {
                          "id": "${stamp_appi_id_1}"
                        },
                        "name": "requests/failed",
                        "aggregationType": 7,
                        "namespace": "microsoft.insights/components",
                        "metricVisualization": {
                          "displayName": "${stamp_location_1} - Failed requests",
                          "resourceDisplayName": "${stamp_appi_name_1}",
                          "color": "#AA558C"
                        }
                      }
                    ],
                    "title": "Failed requests",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 3,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true,
                      "destinationBlade": {
                        "bladeName": "ResourceMenuBlade",
                        "parameters": {
                          "id": "${stamp_appi_id_0}",
                          "menuid": "failures"
                        },
                        "extensionName": "HubsExtension",
                        "options": {
                          "parameters": {
                            "id": "${stamp_appi_id_0}",
                            "menuid": "failures"
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "13": {
          "position": {
            "x": 0,
            "y": 5,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "BackendRequestCount",
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Backend Request Count",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Backend request count",
                    "titleKind": 2,
                    "grouping": {
                      "dimension": "Backend"
                    },
                    "visualization": {
                      "chartType": 2
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "BackendRequestCount",
                        "aggregationType": 1,
                        "metricVisualization": {
                          "displayName": "Backend Request Count",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Backend request count",
                    "titleKind": 2,
                    "grouping": {
                      "dimension": "Backend"
                    },
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                }
              }
            }
          }
        },
        "14": {
          "position": {
            "x": 5,
            "y": 5,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "NormalizedRUConsumption",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Normalized RU Consumption"
                        }
                      }
                    ],
                    "title": "RU consumption",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "grouping": {
                      "dimension": "CollectionName",
                      "sort": 2,
                      "top": 10
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "NormalizedRUConsumption",
                        "aggregationType": 3,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Normalized RU Consumption"
                        }
                      }
                    ],
                    "title": "RU consumption",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    },
                    "grouping": {
                      "dimension": "CollectionName",
                      "sort": 2,
                      "top": 10
                    }
                  }
                }
              }
            }
          }
        },
        "15": {
          "position": {
            "x": 11,
            "y": 5,
            "colSpan": 10,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "## AKS clusters",
                  "title": "",
                  "subtitle": "",
                  "markdownSource": 1,
                  "markdownUri": null
                }
              }
            }
          }
        },
        "16": {
          "position": {
            "x": 11,
            "y": 6,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_aks_id_0}"
                        },
                        "name": "node_cpu_usage_percentage",
                        "aggregationType": 4,
                        "namespace": "microsoft.containerservice/managedclusters",
                        "metricVisualization": {
                          "displayName": "CPU Usage Percentage"
                        }
                      }
                    ],
                    "title": "${stamp_location_0} - CPU usage percentage by node",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "grouping": {
                      "dimension": "node",
                      "sort": 2,
                      "top": 10
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_aks_id_0}"
                        },
                        "name": "node_cpu_usage_percentage",
                        "aggregationType": 4,
                        "namespace": "microsoft.containerservice/managedclusters",
                        "metricVisualization": {
                          "displayName": "CPU Usage Percentage"
                        }
                      }
                    ],
                    "title": "${stamp_location_0} - CPU usage percentage by node",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    },
                    "grouping": {
                      "dimension": "node",
                      "sort": 2,
                      "top": 10
                    }
                  }
                }
              }
            }
          }
        },
        "17": {
          "position": {
            "x": 16,
            "y": 6,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_aks_id_1}"
                        },
                        "name": "node_cpu_usage_percentage",
                        "aggregationType": 4,
                        "namespace": "microsoft.containerservice/managedclusters",
                        "metricVisualization": {
                          "displayName": "CPU Usage Percentage"
                        }
                      }
                    ],
                    "title": "${stamp_location_1} - CPU usage percentage by node",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "grouping": {
                      "dimension": "node",
                      "sort": 2,
                      "top": 10
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${stamp_aks_id_1}"
                        },
                        "name": "node_cpu_usage_percentage",
                        "aggregationType": 4,
                        "namespace": "microsoft.containerservice/managedclusters",
                        "metricVisualization": {
                          "displayName": "CPU Usage Percentage"
                        }
                      }
                    ],
                    "title": "${stamp_location_1} - CPU usage percentage by node",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    },
                    "grouping": {
                      "dimension": "node",
                      "sort": 2,
                      "top": 10
                    }
                  }
                }
              }
            }
          }
        },
        "18": {
          "position": {
            "x": 0,
            "y": 8,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "sharedTimeRange",
                "isOptional": true
              },
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "BackendHealthPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Backend Health Percentage",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Backend health percentage",
                    "titleKind": 2,
                    "grouping": {
                      "dimension": "Backend"
                    },
                    "visualization": {
                      "chartType": 2
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                },
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${front_door_id}"
                        },
                        "name": "BackendHealthPercentage",
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Backend Health Percentage",
                          "resourceDisplayName": "${front_door_name}"
                        }
                      }
                    ],
                    "title": "Backend health percentage",
                    "titleKind": 2,
                    "grouping": {
                      "dimension": "Backend"
                    },
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    },
                    "openBladeOnClick": {
                      "openBlade": true
                    }
                  }
                }
              }
            }
          }
        },
        "19": {
          "position": {
            "x": 11,
            "y": 9,
            "colSpan": 5,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${stamp_aks_id_0}",
                "isOptional": true
              },
              {
                "name": "TimeContext",
                "value": null,
                "isOptional": true
              },
              {
                "name": "ResourceIds",
                "value": [
                  "${stamp_aks_id_0}"
                ],
                "isOptional": true
              },
              {
                "name": "ConfigurationId",
                "value": "Community-Workbooks/AKS/Deployments and HPAs",
                "isOptional": true
              },
              {
                "name": "Type",
                "value": "container-insights",
                "isOptional": true
              },
              {
                "name": "GalleryResourceType",
                "value": "microsoft.containerservice/managedclusters",
                "isOptional": true
              },
              {
                "name": "PinName",
                "value": "${stamp_location_0} - Deployments",
                "isOptional": true
              },
              {
                "name": "StepSettings",
                "value": "{\"version\":\"KqlItem/1.0\",\"query\":\"let data = materialize(\\r\\nInsightsMetrics\\r\\n| where Name == \\\"kube_deployment_status_replicas_ready\\\"\\r\\n| extend Tags = parse_json(Tags)\\r\\n| extend ClusterId = Tags[\\\"container.azm.ms/clusterId\\\"]\\r\\n{clusterIdWhereClause}\\r\\n| where Tags.deployment in ({deploymentName})\\r\\n| extend Deployment = tostring(Tags.deployment)\\r\\n| extend k8sNamespace = tostring(Tags.k8sNamespace)\\r\\n| extend Ready = Val/Tags.spec_replicas * 100, Available = Val/Tags.status_replicas_available * 100\\r\\n| project k8sNamespace, Deployment, Ready, Available, TimeGenerated, Tags\\r\\n);\\r\\nlet data2 = data\\r\\n| extend Age = (now() - todatetime(Tags[\\\"creationTime\\\"]))/1m\\r\\n| summarize arg_max(TimeGenerated, *) by k8sNamespace, Deployment\\r\\n| project k8sNamespace, Deployment, Age, Ready, Available;\\r\\nlet ReadyData = data\\r\\n| make-series ReadyTrend = avg(Ready) default = 0 on TimeGenerated from {timeRange:start} to {timeRange:end} step {timeRange:grain} by k8sNamespace, Deployment;\\r\\nlet AvailableData = data\\r\\n| make-series AvailableTrend = avg(Available) default = 0 on TimeGenerated from {timeRange:start} to {timeRange:end} step {timeRange:grain} by k8sNamespace, Deployment;\\r\\ndata2\\r\\n| join kind = inner(ReadyData) on k8sNamespace, Deployment \\r\\n| join kind = inner(AvailableData) on k8sNamespace, Deployment\\r\\n| extend ReadyCase = case(Ready == 100, \\\"Healthy\\\", \\\"Warning\\\"),   AvailableCase = case(Available == 100, \\\"Healthy\\\", \\\"Warning\\\")\\r\\n| extend Overall = case(ReadyCase == \\\"Healthy\\\" and AvailableCase == \\\"Healthy\\\", \\\"Healthy\\\", \\\"Warning\\\")\\r\\n| extend OverallFilterStatus = case('{OverallFilter}' contains \\\"Healthy\\\", \\\"Healthy\\\", '{OverallFilter}' contains \\\"Warning\\\", \\\"Warning\\\", \\\"Healthy, Warning\\\")\\r\\n| where OverallFilterStatus has Overall\\r\\n| project Deployment, Age, Ready, ReadyTrend, Available, AvailableTrend\\r\\n| sort by Ready asc\\r\\n\",\"size\":0,\"showAnalytics\":true,\"timeContext\":{\"durationMs\":86400000},\"showExportToExcel\":true,\"queryType\":0,\"resourceType\":\"{resourceType}\",\"crossComponentResources\":[\"{resource}\"],\"visualization\":\"table\",\"gridSettings\":{\"formatters\":[{\"columnMatch\":\"Age\",\"formatter\":0,\"numberFormat\":{\"unit\":25,\"options\":{\"style\":\"decimal\",\"useGrouping\":false,\"maximumFractionDigits\":1}}},{\"columnMatch\":\"Ready\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"2\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"useGrouping\":false,\"maximumFractionDigits\":1}}},{\"columnMatch\":\"ReadyTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}},{\"columnMatch\":\"Updated\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"warning\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"maximumFractionDigits\":1}}},{\"columnMatch\":\"UpdatedTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}},{\"columnMatch\":\"Available\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"warning\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"maximumFractionDigits\":1}}},{\"columnMatch\":\"AvailableTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}}],\"filter\":true,\"sortBy\":[{\"itemKey\":\"Deployment\",\"sortOrder\":2}],\"labelSettings\":[{\"columnId\":\"Deployment\"},{\"columnId\":\"Ready\"},{\"columnId\":\"ReadyTrend\"},{\"columnId\":\"Available\"},{\"columnId\":\"AvailableTrend\"}]},\"sortBy\":[{\"itemKey\":\"Deployment\",\"sortOrder\":2}],\"tileSettings\":{\"titleContent\":{\"columnMatch\":\"Ready\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"colors\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"1\",\"representation\":null,\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":null,\"text\":\"{0}{1}\"}]}},\"showBorder\":false}}",
                "isOptional": true
              },
              {
                "name": "ParameterValues",
                "value": {
                  "timeRange": {
                    "type": 4,
                    "value": {
                      "durationMs": 3600000
                    },
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Last hour",
                    "displayName": "Time Range",
                    "formattedValue": "Last hour"
                  },
                  "resource": {
                    "type": 5,
                    "value": "${stamp_aks_id_0}",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Any one",
                    "displayName": "resource",
                    "specialValue": "value::1",
                    "formattedValue": "${stamp_aks_id_0}"
                  },
                  "resourceType": {
                    "type": 7,
                    "value": "microsoft.containerservice/managedclusters",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Any one",
                    "displayName": "resourceType",
                    "specialValue": "value::1",
                    "formattedValue": "microsoft.containerservice/managedclusters"
                  },
                  "clusterId": {
                    "type": 1,
                    "value": "${stamp_aks_id_0}",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "${stamp_aks_id_0}",
                    "displayName": "clusterId",
                    "formattedValue": "${stamp_aks_id_0}"
                  },
                  "clusterIdWhereClause": {
                    "type": 1,
                    "value": "| where \"a\" == \"a\"",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "| where \"a\" == \"a\"",
                    "displayName": "clusterIdWhereClause",
                    "formattedValue": "| where \"a\" == \"a\""
                  },
                  "namespace": {
                    "type": 2,
                    "value": [
                      "workload"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "workload",
                    "displayName": "Namespace",
                    "formattedValue": "'workload'"
                  },
                  "deploymentName": {
                    "type": 2,
                    "value": [
                      "catalogservice-deploy",
                      "backgroundprocessor-deploy",
                      "healthservice-deploy"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "All",
                    "displayName": "Deployment",
                    "specialValue": [
                      "value::all"
                    ],
                    "formattedValue": "'catalogservice-deploy','backgroundprocessor-deploy','healthservice-deploy'"
                  },
                  "hpa": {
                    "type": 2,
                    "value": [
                      "catalogservice-autoscaler",
                      "backgroundprocessor-autoscaler",
                      "healthservice-autoscaler"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "All",
                    "displayName": "HPA",
                    "specialValue": [
                      "value::all"
                    ],
                    "formattedValue": "'catalogservice-autoscaler','backgroundprocessor-autoscaler','healthservice-autoscaler'"
                  },
                  "selectedTab": {
                    "type": 1,
                    "value": "Deployment",
                    "formattedValue": "Deployment"
                  },
                  "OverallFilter": {
                    "value": "*",
                    "formattedValue": "*",
                    "labelValue": "*",
                    "type": 1
                  }
                },
                "isOptional": true
              },
              {
                "name": "Location",
                "isOptional": true
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/PinnedNotebookQueryPart",
            "savedContainerState": {
              "partTitle": "${stamp_location_0} - Deployments",
              "assetName": "${stamp_aks_name_0} (Last hour @ 25. 6. 13:45)"
            }
          }
        },
        "20": {
          "position": {
            "x": 16,
            "y": 9,
            "colSpan": 5,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${stamp_aks_id_1}",
                "isOptional": true
              },
              {
                "name": "TimeContext",
                "value": null,
                "isOptional": true
              },
              {
                "name": "ResourceIds",
                "value": [
                  "${stamp_aks_id_1}"
                ],
                "isOptional": true
              },
              {
                "name": "ConfigurationId",
                "value": "Community-Workbooks/AKS/Deployments and HPAs",
                "isOptional": true
              },
              {
                "name": "Type",
                "value": "container-insights",
                "isOptional": true
              },
              {
                "name": "GalleryResourceType",
                "value": "microsoft.containerservice/managedclusters",
                "isOptional": true
              },
              {
                "name": "PinName",
                "value": "${stamp_location_1} - Deployments",
                "isOptional": true
              },
              {
                "name": "StepSettings",
                "value": "{\"version\":\"KqlItem/1.0\",\"query\":\"let data = materialize(\\r\\nInsightsMetrics\\r\\n| where Name == \\\"kube_deployment_status_replicas_ready\\\"\\r\\n| extend Tags = parse_json(Tags)\\r\\n| extend ClusterId = Tags[\\\"container.azm.ms/clusterId\\\"]\\r\\n{clusterIdWhereClause}\\r\\n| where Tags.deployment in ({deploymentName})\\r\\n| extend Deployment = tostring(Tags.deployment)\\r\\n| extend k8sNamespace = tostring(Tags.k8sNamespace)\\r\\n| extend Ready = Val/Tags.spec_replicas * 100, Available = Val/Tags.status_replicas_available * 100\\r\\n| project k8sNamespace, Deployment, Ready, Available, TimeGenerated, Tags\\r\\n);\\r\\nlet data2 = data\\r\\n| extend Age = (now() - todatetime(Tags[\\\"creationTime\\\"]))/1m\\r\\n| summarize arg_max(TimeGenerated, *) by k8sNamespace, Deployment\\r\\n| project k8sNamespace, Deployment, Age, Ready, Available;\\r\\nlet ReadyData = data\\r\\n| make-series ReadyTrend = avg(Ready) default = 0 on TimeGenerated from {timeRange:start} to {timeRange:end} step {timeRange:grain} by k8sNamespace, Deployment;\\r\\nlet AvailableData = data\\r\\n| make-series AvailableTrend = avg(Available) default = 0 on TimeGenerated from {timeRange:start} to {timeRange:end} step {timeRange:grain} by k8sNamespace, Deployment;\\r\\ndata2\\r\\n| join kind = inner(ReadyData) on k8sNamespace, Deployment \\r\\n| join kind = inner(AvailableData) on k8sNamespace, Deployment\\r\\n| extend ReadyCase = case(Ready == 100, \\\"Healthy\\\", \\\"Warning\\\"),  AvailableCase = case(Available == 100, \\\"Healthy\\\", \\\"Warning\\\")\\r\\n| extend Overall = case(ReadyCase == \\\"Healthy\\\" and AvailableCase == \\\"Healthy\\\", \\\"Healthy\\\", \\\"Warning\\\")\\r\\n| extend OverallFilterStatus = case('{OverallFilter}' contains \\\"Healthy\\\", \\\"Healthy\\\", '{OverallFilter}' contains \\\"Warning\\\", \\\"Warning\\\", \\\"Healthy, Warning\\\")\\r\\n| where OverallFilterStatus has Overall\\r\\n| project Deployment, Age, Ready, ReadyTrend,  Available,AvailableTrend\\r\\n| sort by Ready asc\\r\\n\",\"size\":0,\"showAnalytics\":true,\"timeContext\":{\"durationMs\":86400000},\"showExportToExcel\":true,\"queryType\":0,\"resourceType\":\"{resourceType}\",\"crossComponentResources\":[\"{resource}\"],\"visualization\":\"table\",\"gridSettings\":{\"formatters\":[{\"columnMatch\":\"Age\",\"formatter\":0,\"numberFormat\":{\"unit\":25,\"options\":{\"style\":\"decimal\",\"useGrouping\":false,\"maximumFractionDigits\":1}}},{\"columnMatch\":\"Ready\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"2\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"useGrouping\":false,\"maximumFractionDigits\":1}}},{\"columnMatch\":\"ReadyTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}},{\"columnMatch\":\"Updated\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"warning\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"maximumFractionDigits\":1}}},{\"columnMatch\":\"UpdatedTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}},{\"columnMatch\":\"Available\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"icons\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"100\",\"representation\":\"success\",\"text\":\"{0}{1}\"},{\"operator\":\"==\",\"thresholdValue\":\"NaN\",\"representation\":\"more\",\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":\"warning\",\"text\":\"{0}{1}\"}]},\"numberFormat\":{\"unit\":1,\"options\":{\"style\":\"decimal\",\"maximumFractionDigits\":1}}},{\"columnMatch\":\"AvailableTrend\",\"formatter\":9,\"formatOptions\":{\"min\":0,\"max\":100,\"palette\":\"redGreen\"}}],\"filter\":true,\"sortBy\":[{\"itemKey\":\"Deployment\",\"sortOrder\":2}],\"labelSettings\":[{\"columnId\":\"Deployment\"},{\"columnId\":\"Ready\"},{\"columnId\":\"ReadyTrend\"},{\"columnId\":\"Available\"},{\"columnId\":\"AvailableTrend\"}]},\"sortBy\":[{\"itemKey\":\"Deployment\",\"sortOrder\":2}],\"tileSettings\":{\"titleContent\":{\"columnMatch\":\"Ready\",\"formatter\":18,\"formatOptions\":{\"thresholdsOptions\":\"colors\",\"thresholdsGrid\":[{\"operator\":\"==\",\"thresholdValue\":\"1\",\"representation\":null,\"text\":\"{0}{1}\"},{\"operator\":\"Default\",\"thresholdValue\":null,\"representation\":null,\"text\":\"{0}{1}\"}]}},\"showBorder\":false}}",
                "isOptional": true
              },
              {
                "name": "ParameterValues",
                "value": {
                  "timeRange": {
                    "type": 4,
                    "value": {
                      "durationMs": 21600000
                    },
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Last 6 hours",
                    "displayName": "Time Range",
                    "formattedValue": "Last 6 hours"
                  },
                  "resource": {
                    "type": 5,
                    "value": "${stamp_aks_id_1}",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Any one",
                    "displayName": "resource",
                    "specialValue": "value::1",
                    "formattedValue": "${stamp_aks_id_1}"
                  },
                  "resourceType": {
                    "type": 7,
                    "value": "microsoft.containerservice/managedclusters",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "Any one",
                    "displayName": "resourceType",
                    "specialValue": "value::1",
                    "formattedValue": "microsoft.containerservice/managedclusters"
                  },
                  "clusterId": {
                    "type": 1,
                    "value": "${stamp_aks_id_1}",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "${stamp_aks_id_1}",
                    "displayName": "clusterId",
                    "formattedValue": "${stamp_aks_id_1}"
                  },
                  "clusterIdWhereClause": {
                    "type": 1,
                    "value": "| where \"a\" == \"a\"",
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "| where \"a\" == \"a\"",
                    "displayName": "clusterIdWhereClause",
                    "formattedValue": "| where \"a\" == \"a\""
                  },
                  "namespace": {
                    "type": 2,
                    "value": [
                      "workload"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "workload",
                    "displayName": "Namespace",
                    "formattedValue": "'workload'"
                  },
                  "deploymentName": {
                    "type": 2,
                    "value": [
                      "catalogservice-deploy",
                      "backgroundprocessor-deploy",
                      "healthservice-deploy"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "All",
                    "displayName": "Deployment",
                    "specialValue": [
                      "value::all"
                    ],
                    "formattedValue": "'catalogservice-deploy','backgroundprocessor-deploy','healthservice-deploy'"
                  },
                  "hpa": {
                    "type": 2,
                    "value": [
                      "catalogservice-autoscaler",
                      "backgroundprocessor-autoscaler",
                      "healthservice-autoscaler"
                    ],
                    "isPending": false,
                    "isWaiting": false,
                    "isFailed": false,
                    "isGlobal": false,
                    "labelValue": "All",
                    "displayName": "HPA",
                    "specialValue": [
                      "value::all"
                    ],
                    "formattedValue": "'catalogservice-autoscaler','backgroundprocessor-autoscaler','healthservice-autoscaler'"
                  },
                  "selectedTab": {
                    "type": 1,
                    "value": "Deployment",
                    "formattedValue": "Deployment"
                  },
                  "OverallFilter": {
                    "value": "*",
                    "formattedValue": "*",
                    "labelValue": "*",
                    "type": 1
                  }
                },
                "isOptional": true
              },
              {
                "name": "Location",
                "isOptional": true
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/PinnedNotebookQueryPart",
            "savedContainerState": {
              "partTitle": "${stamp_location_1} - Deployments",
              "assetName": "${stamp_aks_name_1} (Last hour @ 25. 6. 13:45)"
            }
          }
        },
        "21": {
          "position": {
            "x": 5,
            "y": 8,
            "colSpan": 5,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "ServerSideLatency",
                        "aggregationType": 4,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Server Side Latency"
                        }
                      }
                    ],
                    "title": "Server Side Latency",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      }
                    },
                    "timespan": {
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false,
                      "grain": 1
                    }
                  }
                },
                "isOptional": true
              },
              {
                "name": "sharedTimeRange",
                "isOptional": true
              }
            ],
            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "resourceMetadata": {
                          "id": "${cosmosdb_id}"
                        },
                        "name": "ServerSideLatency",
                        "aggregationType": 4,
                        "namespace": "microsoft.documentdb/databaseaccounts",
                        "metricVisualization": {
                          "displayName": "Server Side Latency"
                        }
                      }
                    ],
                    "title": "Server Side Latency",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "legendVisualization": {
                        "isVisible": true,
                        "position": 2,
                        "hideSubtitle": false
                      },
                      "axisVisualization": {
                        "x": {
                          "isVisible": true,
                          "axisType": 2
                        },
                        "y": {
                          "isVisible": true,
                          "axisType": 1
                        }
                      },
                      "disablePinning": true
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      },
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "model": {
              "format": "utc",
              "granularity": "30m",
              "relative": "4320m"
            },
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 3 days"
            },
            "filteredPartIds": [
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c59949c",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c59949e",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994a0",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994a2",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994a4",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994a6",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994aa",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994ac",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994ae",
              "StartboardPart-MonitorChartPart-1b4b7d17-c58b-450f-9198-09da3c5994b0",
              "StartboardPart-PinnedNotebookQueryPart-1b4b7d17-c58b-450f-9198-09da3c5994b2",
              "StartboardPart-PinnedNotebookQueryPart-1b4b7d17-c58b-450f-9198-09da3c5994b4"
            ]
          }
        }
      }
    }
  }
}
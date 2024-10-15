# Instalación de Kubernetes en EC2 utilizando Kubeadm

Este documento detalla el proceso de instalación de un clúster de Kubernetes en dos instancias EC2: una para el control plane y otra para el worker node, utilizando `kubeadm`.

## ¿Qué es Kubeadm?

`Kubeadm` es una herramienta diseñada para facilitar la instalación y configuración de clústeres de Kubernetes. Proporciona un conjunto de comandos que permiten inicializar un clúster, unir nodos y gestionar la configuración de los componentes esenciales de Kubernetes. Con `kubeadm`, los administradores pueden establecer un clúster de Kubernetes de forma rápida y eficiente, siguiendo buenas prácticas.
**Documento oficial de instalacion**
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## ¿Qué es un Container Runtime?

Un **container runtime** es la capa responsable de ejecutar y gestionar contenedores. En el contexto de Kubernetes, el container runtime se encarga de crear, ejecutar y detener los contenedores en cada nodo del clúster. Kubernetes soporta varios container runtimes, siendo los más comunes:

- **Docker**: El más utilizado, que permite gestionar contenedores y su ecosistema.
- **containerd**: Un runtime ligero que es parte del proyecto Docker, usado en entornos más especializados.
- **CRI-O**: Un runtime diseñado específicamente para Kubernetes, que cumple con la interfaz CRI (Container Runtime Interface).
  
**Documento oficial Container Runtine**
- https://kubernetes.io/docs/setup/production-environment/container-runtimes/

## Requisitos Previos

- **Cuenta de AWS**: Necesitarás una cuenta de AWS para crear instancias EC2.
- **AWS CLI**: Instalado y configurado para interactuar con tu cuenta de AWS.
- **Clave SSH**: Para acceder a las instancias EC2.
- **Conocimientos básicos de Kubernetes**: Comprender la arquitectura básica de Kubernetes y sus componentes.

## Pasos para la Instalación

### 1. Crear las Instancias EC2

Crea dos instancias EC2:
- **Control Plane**: Esta instancia ejecuta el servidor API de Kubernetes y gestiona el clúster.
- **Worker Node**: Esta instancia ejecuta los contenedores y las aplicaciones que se ejecutan en el clúster.

### 2. Conectar a la Instancia del Control Plane

Accede a la instancia del control plane mediante SSH:

ssh -i YourKeyPair.pem ubuntu@<CONTROL_PLANE_IP>

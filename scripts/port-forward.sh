#!/bin/bash

##############################################################################
# Port Forward Manager
# Description: Manages port forwarding for all services
# Author: OSTAD 2025 - Module 7
##############################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if port forwarding is running
check_port_forward() {
    local service=$1
    ps aux | grep "port-forward.*$service" | grep -v grep > /dev/null
    return $?
}

# Function to start port forward
start_port_forward() {
    local namespace=$1
    local service=$2
    local local_port=$3
    local remote_port=$4
    local name=$5
    
    if check_port_forward "$service"; then
        print_warn "$name is already running"
    else
        print_info "Starting $name port forward..."
        nohup kubectl port-forward -n $namespace svc/$service $local_port:$remote_port --address='0.0.0.0' \
            > /tmp/pf-$name.log 2>&1 &
        sleep 2
        if check_port_forward "$service"; then
            print_info "$name is now accessible at http://<EC2-IP>:$local_port"
        else
            print_error "Failed to start $name port forward. Check /tmp/pf-$name.log"
        fi
    fi
}

# Function to stop port forward
stop_port_forward() {
    local service=$1
    local name=$2
    
    if check_port_forward "$service"; then
        print_info "Stopping $name port forward..."
        pkill -f "port-forward.*$service"
        print_info "$name port forward stopped"
    else
        print_warn "$name port forward is not running"
    fi
}

# Function to show status
show_status() {
    echo ""
    echo "============================================"
    echo "Port Forward Status"
    echo "============================================"
    echo ""
    
    local services=("prometheus-grafana:Grafana" \
                   "prometheus-kube-prometheus-prometheus:Prometheus" \
                   "nginx-service:Nginx" \
                   "esim-backend:eSIM-Backend")
    
    for entry in "${services[@]}"; do
        IFS=':' read -r service name <<< "$entry"
        if check_port_forward "$service"; then
            local pid=$(ps aux | grep "port-forward.*$service" | grep -v grep | awk '{print $2}')
            echo -e "$name: ${GREEN}RUNNING${NC} (PID: $pid)"
        else
            echo -e "$name: ${RED}STOPPED${NC}"
        fi
    done
    
    echo ""
}

# Function to stop all
stop_all() {
    print_info "Stopping all port forwards..."
    pkill -f "kubectl port-forward"
    print_info "All port forwards stopped"
}

# Main script
case "$1" in
    start)
        echo ""
        echo "============================================"
        echo "Starting Port Forwards"
        echo "============================================"
        echo ""
        
        # Start Grafana
        start_port_forward "monitoring" "prometheus-grafana" "3000" "80" "Grafana"
        
        # Start Prometheus
        start_port_forward "monitoring" "prometheus-kube-prometheus-prometheus" "9090" "9090" "Prometheus"
        
        # Start Nginx (optional)
        if [ "$2" == "--with-app" ]; then
            start_port_forward "application" "nginx-service" "8080" "80" "Nginx"
        fi
        
        # Start eSIM Backend (optional)
        if [ "$2" == "--with-esim" ]; then
            start_port_forward "esim" "esim-backend" "3001" "3000" "eSIM-Backend"
        fi
        
        # Start both apps
        if [ "$2" == "--with-all" ]; then
            start_port_forward "application" "nginx-service" "8080" "80" "Nginx"
            start_port_forward "esim" "esim-backend" "3001" "3000" "eSIM-Backend"
        fi
        
        echo ""
        show_status
        
        echo "Access URLs:"
        echo "  Grafana:    http://<EC2-IP>:3000"
        echo "  Prometheus: http://<EC2-IP>:9090"
        if [ "$2" == "--with-app" ]; then
            echo "  Nginx:      http://<EC2-IP>:8080"
        fi
        if [ "$2" == "--with-esim" ]; then
            echo "  eSIM Backend: http://<EC2-IP>:3001"
        fi
        if [ "$2" == "--with-all" ]; then
            echo "  Nginx:        http://<EC2-IP>:8080"
            echo "  eSIM Backend: http://<EC2-IP>:3001"
        fi
        echo ""
        ;;
        
    stop)
        echo ""
        echo "============================================"
        echo "Stopping Port Forwards"
        echo "============================================"
        echo ""
        
        if [ "$2" == "grafana" ]; then
            stop_port_forward "prometheus-grafana" "Grafana"
        elif [ "$2" == "prometheus" ]; then
            stop_port_forward "prometheus-kube-prometheus-prometheus" "Prometheus"
        elif [ "$2" == "nginx" ]; then
            stop_port_forward "nginx-service" "Nginx"
        elif [ "$2" == "esim" ]; then
            stop_port_forward "esim-backend" "eSIM-Backend"
        else
            stop_all
        fi
        
        echo ""
        show_status
        ;;
        
    restart)
        echo ""
        echo "============================================"
        echo "Restarting Port Forwards"
        echo "============================================"
        echo ""
        
        stop_all
        sleep 2
        
        start_port_forward "monitoring" "prometheus-grafana" "3000" "80" "Grafana"
        start_port_forward "monitoring" "prometheus-kube-prometheus-prometheus" "9090" "9090" "Prometheus"
        
        if [ "$2" == "--with-app" ]; then
            start_port_forward "application" "nginx-service" "8080" "80" "Nginx"
        fi
        
        if [ "$2" == "--with-esim" ]; then
            start_port_forward "esim" "esim-backend" "3001" "3000" "eSIM-Backend"
        fi
        
        if [ "$2" == "--with-all" ]; then
            start_port_forward "application" "nginx-service" "8080" "80" "Nginx"
            start_port_forward "esim" "esim-backend" "3001" "3000" "eSIM-Backend"
        fi
        
        echo ""
        show_status
        ;;
        
    status)
        show_status
        
        echo "Log files:"
        echo "  Grafana:      /tmp/pf-Grafana.log"
        echo "  Prometheus:   /tmp/pf-Prometheus.log"
        echo "  Nginx:        /tmp/pf-Nginx.log"
        echo "  eSIM Backend: /tmp/pf-eSIM-Backend.log"
        echo ""
        ;;
        
    logs)
        if [ -z "$2" ]; then
            print_error "Please specify service: grafana, prometheus, or nginx"
            exit 1
        fi
        
        case "$2" in
            grafana)
                tail -f /tmp/pf-Grafana.log
                ;;
            prometheus)
                tail -f /tmp/pf-Prometheus.log
                ;;
            nginx)
                tail -f /tmp/pf-Nginx.log
                ;;
            esim)
                tail -f /tmp/pf-eSIM-Backend.log
                ;;
            *)
                print_error "Unknown service: $2"
                exit 1
                ;;
        esac
        ;;
        
    *)
        echo ""
        echo "Port Forward Manager"
        echo "===================="
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs} [options]"
        echo ""
        echo "Commands:"
        echo "  start [--with-app|--with-esim|--with-all]   Start port forwards"
        echo "  stop [service]                                Stop port forwards"
        echo "  restart [--with-app|--with-esim|--with-all]  Restart port forwards"
        echo "  status                                        Show port forward status"
        echo "  logs <service>                                Show logs for service"
        echo ""
        echo "Options:"
        echo "  --with-app    Include Nginx application"
        echo "  --with-esim   Include eSIM backend"
        echo "  --with-all    Include both Nginx and eSIM"
        echo ""
        echo "Services:"
        echo "  grafana, prometheus, nginx, esim"
        echo ""
        echo "Examples:"
        echo "  $0 start                      # Start Grafana and Prometheus only"
        echo "  $0 start --with-app           # Start with Nginx"
        echo "  $0 start --with-esim          # Start with eSIM backend"
        echo "  $0 start --with-all           # Start with both apps"
        echo "  $0 stop                       # Stop all port forwards"
        echo "  $0 stop esim                  # Stop only eSIM backend"
        echo "  $0 restart --with-all         # Restart all services"
        echo "  $0 status                     # Show current status"
        echo "  $0 logs esim                  # Show eSIM backend logs"
        echo ""
        exit 1
        ;;
esac

exit 0

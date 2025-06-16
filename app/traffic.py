import psutil
import socket

def get_main_interface():
    # Попробуем определить интерфейс, через который идет default route
    # Работает на Linux и macOS, для Windows — см. примечания ниже
    try:
        # Открываем UDP socket, не отправляем, просто узнаем локальный адрес
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        # Ищем интерфейс по IP
        for iface, addrs in psutil.net_if_addrs().items():
            for addr in addrs:
                if addr.family == socket.AF_INET and addr.address == local_ip:
                    return iface
    except Exception:
        pass
    # fallback: берем первый не loopback интерфейс с трафиком
    stats = psutil.net_io_counters(pernic=True)
    for name, stat in stats.items():
        if not name.startswith("lo") and (stat.bytes_sent > 0 or stat.bytes_recv > 0):
            return name
    return None

def get_interface_traffic():
    iface = get_main_interface()
    stats = psutil.net_io_counters(pernic=True)
    if iface and iface in stats:
        return {
            "interface": iface,
            "bytes_sent": stats[iface].bytes_sent,
            "bytes_recv": stats[iface].bytes_recv,
            "total": stats[iface].bytes_sent + stats[iface].bytes_recv
        }
    else:
        return {
            "interface": None,
            "bytes_sent": 0,
            "bytes_recv": 0,
            "total": 0
        }
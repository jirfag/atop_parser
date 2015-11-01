# -*- coding: utf-8 -*-
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import json
import sys

def draw_pdisk(lines, enable_date):
    days_n = len(lines) / 17
    assert days_n * 17 == len(lines)

    only_write = False

    stats = []
    for i in range(days_n):
        progs = {}
        for line in lines[i*17+1:i*17+16]:
            if only_write:
                progs[line.split(':')[0]] = {'rw': int(line.split(' ')[5][:-1])}
            else:
                progs[line.split(':')[0]] = {'rw': int(line.split(' ')[1].split('%')[0])}
        day = lines[i*17].split(' ')[1].split('_')[1]
        stats.append({
            'day': day,
            'total': progs['total']['rw'],
            'mpopd': progs['mpopd']['rw'],
            'storaged': progs['storaged']['rw'],
        })

    stats = stats[-180:]

    #print(stats)
    x = list(range(len(stats)))
    x_labels = [s['day'][4:] for s in stats]
    plt.xticks(x, x_labels)
    new_storing_enable_pos = x_labels.index(enable_date)
    plt.ylabel('disk usage')

    line_total, = plt.plot(x, [s['total'] for s in stats], color='red', label='total')
    #line_mpopd, = plt.plot(x, [s['mpopd'] for s in stats], color='green', label='mpopd')
    #line_storaged, = plt.plot(x, [s['storaged'] for s in stats], color='blue', label='storaged')
    #plt.legend([line_total, line_mpopd, line_storaged], ['total', 'mpopd', 'storaged'])
    #if only_write:
    #    plt.ylim([0,80e3])
    #else:
    #    plt.ylim([0,200e3])
    plt.axvline(x=new_storing_enable_pos, linewidth=1, color='black')

def draw_cpu(lines, enable_date):
    stats = [json.loads(line) for line in lines]
    x = list(range(len(stats)))
    x_labels = [s['date'][4:] for s in stats]
    plt.xticks(x, x_labels)
    new_storing_enable_pos = x_labels.index(enable_date)
    xline = plt.axvline(x=new_storing_enable_pos, linewidth=1, color='black')
    plt.ylabel(u'Использование CPU, условных единиц')
    plt.xlabel(u'Дата')
    line_t, = plt.plot(x, [s['t'] for s in stats], color='red', label='total')
    plt.ylim([0,18e3])
#    line_s, = plt.plot(x, [s['s'] for s in stats], color='black', label='total')
#    line_u, = plt.plot(x, [s['u'] for s in stats], color='blue', label='total')
#    line_w, = plt.plot(x, [s['w'] for s in stats], color='green', label='total')
#    plt.legend([line_t, line_s, line_u, line_w], ['total', 'system', 'user', 'wait'])
    plt.legend([xline], [u'Включение новой покладки'])

def draw_disk(lines, enable_date):
    stats = [json.loads(line) for line in lines]
    x = list(range(len(stats)))
    x_labels = [s['date'][4:] for s in stats]
    plt.xticks(x, x_labels)
    new_storing_enable_pos = x_labels.index(enable_date)
    xline = plt.axvline(x=new_storing_enable_pos, linewidth=1, color='black')
    plt.legend([xline], [u'Включение новой покладки'])
    plt.ylabel(u'Использование диска, условных единиц')
    plt.xlabel(u'Дата')
#    plt.ylim([0,700])
#    line_i, = plt.plot(x, [s['i'] for s in stats], color='red')
#    line_i50, = plt.plot(x, [s['i50'] for s in stats], color='gray')
#    line_i95, = plt.plot(x, [s['i95'] for s in stats], color='orange')
#    line_r, = plt.plot(x, [s['r'] for s in stats], color='black')
#    line_w, = plt.plot(x, [s['w'] for s in stats], color='blue')
    line_t, = plt.plot(x, [s['w'] + s['r'] for s in stats], color='red')
#    line_q, = plt.plot(x, [s['q'] for s in stats], color='pink')
#    plt.legend([line_i, line_i50, line_i95, line_r, line_w], ['io_ms', 'io_ms_50', 'io_ms_95', 'read', 'write'])

def draw_net(lines, enable_date):
    stats = [json.loads(line) for line in lines]
    x = list(range(len(stats)))
    x_labels = [s['date'][4:] for s in stats]
    plt.xticks(x, x_labels)
    new_storing_enable_pos = x_labels.index(enable_date)
    plt.axvline(x=new_storing_enable_pos, linewidth=1, color='black')
    plt.ylabel('net usage')
    line_in, = plt.plot(x, [s['in'] for s in stats], color='red')
    line_out, = plt.plot(x, [s['out'] for s in stats], color='blue')
    plt.legend([line_in, line_out], ['in', 'out'])

def draw_mem(lines, enable_date):
    stats = [json.loads(line) for line in lines]
    x = list(range(len(stats)))
    x_labels = [s['date'][4:] for s in stats]
    plt.xticks(x, x_labels)
    new_storing_enable_pos = x_labels.index(enable_date)
    xline = plt.axvline(x=new_storing_enable_pos, linewidth=1, color='black')
    plt.legend([xline], [u'Включение новой покладки'])
    plt.xlabel(u'Дата')
    plt.ylabel(u'Кол-во свободной памяти, условных единиц')
    #line_free, = plt.plot(x, [s['free'] for s in stats], color='red')
    #line_cached, = plt.plot(x, [s['cached'] for s in stats], color='green')
    #line_buf, = plt.plot(x, [s['buf'] for s in stats], color='blue')
    line_total, = plt.plot(x, [s['buf'] + s['cached'] + s['free'] for s in stats], color='red')
    #plt.legend([line_free, line_cached, line_buf], ['free', 'cached', 'buf'])

    plt.ylim([0,200])

lines = sys.stdin.read().splitlines()

arg = sys.argv[1]
enable_date = sys.argv[2]

if arg == 'cpu':
    draw_cpu(lines, enable_date)
elif arg == 'pdisk':
    draw_pdisk(lines, enable_date)
elif arg == 'disk':
    draw_disk(lines, enable_date)
elif arg == 'net':
    draw_net(lines, enable_date)
elif arg == 'mem':
    draw_mem(lines, enable_date)

plt.grid(True)
plt.show()

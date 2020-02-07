#!/usr/bin/env python2
# encoding: utf-8

import os
import sys
from collections import defaultdict
from pymunin import MuninGraph, MuninPlugin, muninMain


class MuninSupervisordProcessStatsPlugin(MuninPlugin):
    plugin_name = 'debugproxy_stats'
    isMultigraph = True
    isMultiInstance = True

    def __init__(self, argv=(), env=None, debug=False):
        MuninPlugin.__init__(self, argv, env, debug)

        graphs = [
            ('stats_active_users', 'Active Users',
             'Active Users', 'Active Users', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_authorized_requests', 'Authorized Requests',
             'Authorized Requests', 'Authorized Requests', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_https_connects', 'HTTPS Connects',
             'HTTPS Connects', 'HTTPS Connects', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_request_errors', 'Request Errors',
             'Request Errors', 'Request Errors', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_request_intercepted', 'Intercepted Requests',
             'Intercepted Requests', 'Intercepted Requests', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_non_activated_users', 'Non-activated users',
             'Non-activated users', 'Non-activated users', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_not_authorized_requests', 'Not Authorized Requests',
             'Not Authorized Requests', 'Not Authorized Requests', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_proxy_sessions', 'Proxy Sessions',
             'Proxy Sessions', 'Proxy Sessions', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_ratelimited_requests', 'Rate limited requests',
             'Proxy Sessions', 'Proxy Sessions', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_requests', 'Requests',
             'Requests', 'Requests', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_responses', 'Responses',
             'Responses', 'Responses', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_saved_requests', 'Saved Requests',
             'Saved Requests', 'Saved Requests', 'LINE2', 'GAUGE', '--lower-limit 0'),

            ('stats_worker_queue', 'Worker Queue',
             'Worker Queue', 'Worker Queue', 'LINE2', 'GAUGE', '--lower-limit 0'),
        ]

        self._category = 'debugproxy'
        self.identity = 'debugproxy'
        self._stats = defaultdict(dict)

        for (graph_name, graph_title, graph_info, graph_vlabel, graph_draw, graph_type, graph_args) in graphs:
            if self.graphEnabled(graph_name):
                graph = MuninGraph('debugProxy - {0}'.format(graph_title),
                                   self._category, info=graph_info, vlabel=graph_vlabel, args=graph_args)

                graph.addField("count",
                               "count", draw=graph_draw,
                               type=graph_type, info=graph_info,
                               min=0)

                self.appendGraph(graph_name, graph)

    def retrieveVals(self):
        """Retrieve values for graphs."""

        with open('/var/log/debugproxy/stats') as f:
            lines = f.readlines()

        def get_value(name):
            rows = filter(lambda x: x.startswith(name), lines)
            if len(rows) == 1:
                return rows[0].split(' ')[1]

        sessions = get_value('proxy_sessions.value')
        requests = get_value('requests.value')
        users = get_value('active_users.value')
        not_active_users = get_value('not_active_users.value')
        request_rate = get_value('requests_5_minute.value')
        connect_rate = get_value('connects_5_minute.value')
        error_rate = get_value('errors_5_minutes.value')
        intercept_rate =get_value('intercepted_5_minute.value')
        not_authorized_rate = get_value('not_authorized_5_minute.value')
        authorized_rate = get_value('authorized_5_minute.value')
        ratelimited_rate = get_value('ratelimited_5_minute.value')
        responses_rate = get_value('responses_5_minute.value')
        worker_queue = get_value('worker_queue.value')

        if users:
            self._stats['stats_active_users']['count'] = users

        if authorized_rate:
            self._stats['stats_authorized_requests']['count'] = authorized_rate

        if connect_rate:
            self._stats['stats_https_connects']['count'] = connect_rate

        if error_rate:
            self._stats['stats_request_errors']['count'] = error_rate

        if intercept_rate:
            self._stats['stats_request_intercepted']['count'] = intercept_rate

        if not_active_users:
            self._stats['stats_non_activated_users']['count'] = not_active_users

        if not_authorized_rate:
            self._stats['stats_not_authorized_requests']['count'] = not_authorized_rate

        if sessions:
            self._stats['stats_proxy_sessions']['count'] = sessions

        if ratelimited_rate:
            self._stats['stats_ratelimited_requests']['count'] = ratelimited_rate

        if request_rate:
            self._stats['stats_requests']['count'] = request_rate

        if responses_rate:
            self._stats['stats_responses']['count'] = responses_rate

        if  requests:
            self._stats['stats_saved_requests']['count'] = requests

        if worker_queue:
            self._stats['stats_worker_queue']['count'] = worker_queue


        for graph_name in self.getGraphList():
            for field_name in self.getGraphFieldList(graph_name):
                self.setGraphVal(graph_name, field_name, self._stats[graph_name].get(field_name))

    def autoconf(self):
        """Implements Munin Plugin Auto-Configuration Option.

        @return: True if plugin can be  auto-configured, False otherwise.

        """
        return False


def main():
    sys.exit(muninMain(MuninSupervisordProcessStatsPlugin))


if __name__ == '__main__':
    main()

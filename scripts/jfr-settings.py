import argparse
import re

arg_parser = argparse.ArgumentParser(prog='jfr-settings', description='Convert JFR settings from/to JFR properties')
arg_parser.add_argument('input_file', help='input file')
args = arg_parser.parse_args()


class Event:
    def __init__(self, name):
        self.event_name = name
        self.settings = {}


def convert_jfc_to_jfp(jfc_filename):
    event_name_re = re.compile('.*<event name="([^"]+)">.*')
    setting_re = re.compile('.*<setting name="([^"]+)".*>([^<]+)</setting>.*')
    event_ends_re = re.compile('.*</event>.*')

    current_event = None
    events = []
    with open(jfc_filename, "r") as jfc_file:
        for line in jfc_file:
            match = event_name_re.match(line)
            if match:
                event_name = match.group(1)
                current_event = Event(event_name)
            match = setting_re.match(line)
            if match:
                if not current_event:
                    print("Error parsing event")
                    exit(-1)
                setting_name = match.group(1)
                setting_value = match.group(2)
                current_event.settings[setting_name] = setting_value
            match = event_ends_re.match(line)
            if match:
                events.append(current_event)
                current_event = None
    for event in events:
        for name, value in event.settings.items():
            print('{}#{}={}'.format(event.event_name, name, value))


def convert_jfp_to_jfc(jfp_filename):
    property_re = re.compile('([^#]+)#([^=]+)=([^$]+)')

    events = {}
    with open(jfp_filename, 'r') as jfp_file:
        for line in jfp_file:
            match = property_re.match(line)
            if match:
                event_name = match.group(1)
                setting_name = match.group(2)
                setting_value = match.group(3).rstrip()
                event = events.get(event_name, None)
                if not event:
                    event = Event(event_name)
                    events[event_name] = event
                event.settings[setting_name] = setting_value
    print('<configuration version="2.0">')
    for event_name, event in events.items():
        print('\t<event name="{}">'.format(event.event_name))
        for setting_name, value in event.settings.items():
            print('\t\t<setting name="{}">{}</setting>'.format(setting_name, value))
        print('\t</event>')
        print('')
    print('</configuration>')



input_filename = args.input_file
if input_filename.endswith(".jfc"):
    convert_jfc_to_jfp(input_filename)
if input_filename.endswith(".jfp"):
    convert_jfp_to_jfc(input_filename)






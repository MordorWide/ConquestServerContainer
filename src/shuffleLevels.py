#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import random

def reshuffle_levels(xml_data: str) -> str:
    # Read the XML file
    root = ET.fromstring(xml_data)

    # Get the levels from the XML
    level_node = root.find('Levels')
    if level_node is None:
        raise ValueError("No 'Levels' node found in the XML file.")

    # Load and shuffle the levels
    levels = [ level for level in root.find('Levels') ]
    random.shuffle(levels)

    # Clear the original levels node
    root.remove(level_node)
    # Create a new levels node
    level_node = ET.Element('Levels')

    # Write the shuffled levels back to the XML file
    for level in levels:
        level_node.append(level)

    # Append the new levels node to the root
    root.append(level_node)

    # Prettify the XML output
    ET.indent(root)

    # Save the modified XML file
    return ET.tostring(
        root,
        xml_declaration=True,
        encoding='utf-8',
        method="xml"
    ).decode('utf-8').rstrip("\n") + "\n"

if __name__ == "__main__":
    import sys
    import argparse
    parser = argparse.ArgumentParser(description="Shuffle Levels in the Dedicated.xml file.")

    # Load the XML file from path or stdin
    parser.add_argument('input', nargs='?', type=str, help="Path to the input XML file (default: stdin).")
    parser.add_argument('output', nargs='?', type=str, help="Path to the output XML file (default: stdout).")
    args = parser.parse_args()

    # Read the XML data
    if args.input:
        with open(args.input, 'r') as file:
            xml_data = file.read()
    else:
        xml_data = sys.stdin.read()

    # Reshuffle the levels
    shuffled_xml = reshuffle_levels(xml_data)

    # Write the shuffled XML to the output file or stdout
    if args.output:
        with open(args.output, 'w') as file:
            file.write(shuffled_xml)
    else:
        sys.stdout.write(shuffled_xml)
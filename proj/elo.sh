te = table_entry["MyIngress.interface_mapper"](action="set_output_interface")
te.match['standard_metadata.ingress_port'] = '1'
te.action['out_port'] = '2'
te.insert()

te = table_entry["MyIngress.interface_mapper"](action="set_output_interface")
te.match['standard_metadata.ingress_port'] = '2'
te.action['out_port'] = '1'
te.insert()

for entry in table_entry["MyIngress.interface_mapper"].read():
    print(entry)
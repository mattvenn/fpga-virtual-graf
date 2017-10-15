import jinja2
templateLoader = jinja2.FileSystemLoader( searchpath="./")
templateEnv = jinja2.Environment( loader=templateLoader )

class module():
    def __init__(self):
        self.ports = []
        self.name = None

    def set_name(self, name):
        self.name = name

    def add_port(self, name, direction, type, width):
        print("adding port %s %s %s %s" % (name, direction, type, width))
        self.ports.append({ 'direction' : direction, 'name': name, 'type' : type, 'width': width })

    def get_in_ports(self):
        return [ p for p in self.ports if p['direction'] == 'Input' ]

    def get_out_ports(self):
        return [ p for p in self.ports if p['direction'] == 'Output' ]

    # provide zipped ports for jinja for loop
    def zip_ports(self):
        # equalize length of lists first
        len_diff = len(self.get_in_ports()) - len(self.get_out_ports())
        print(len_diff)
        if len_diff > 0:
            return zip(self.get_in_ports(), self.get_out_ports() + [None] * len_diff)
        else:
            return zip(self.get_in_ports() + [None] * abs(len_diff), self.get_out_ports())

    def render(self, template_file):
        template = templateEnv.get_template(template_file)
        return template.render(module=self)

if __name__ == '__main__':

    mod = module('matts module')
    mod.add_port('clk', 'Input', 'wire', 1 )
    mod.add_port('reset', 'Input', 'wire', 1 )
    mod.add_port('x', 'Output', 'reg', 10 )
    print(mod.render("port_template.dot"))

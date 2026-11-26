local s = import 'lib_lens.jsonnet';

s.basic_rule('python', 
             s.And('foo("...")',
                   s.Regex(@'ABCDE')))



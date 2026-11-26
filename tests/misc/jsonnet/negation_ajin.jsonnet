local s = import 'lib_lens.jsonnet';

s.basic_rule('python', 
             s.And('os.environ',
                   s.Not(s.Or(s.Inside('os.environ.get(...)'),
                              s.Inside('os.environ[...]')))))

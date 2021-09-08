txtreader_sources = [
  'main.vala',
  'window.vala',
]

txtreader_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
]

gnome = import('gnome')

txtreader_sources += gnome.compile_resources('txtreader-resources',
  'txtreader.gresource.xml',
  c_name: 'txtreader'
)

executable('txtreader', txtreader_sources,
  vala_args: '--target-glib=2.50',  dependencies: txtreader_deps,
  install: true,
)

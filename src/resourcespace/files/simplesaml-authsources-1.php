$simplesamlconfig['authsources'] = [
    # This is a authentication source which handles admin authentication.
    'admin' => [# The default is to use core:AdminPassword, but it can be replaced with any authentication source.
        'core:AdminPassword',
    ],
    'resourcespace-sp' => [
        'saml:SP',

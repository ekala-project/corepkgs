{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  protobuf,
  zlib,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "protobuf-c";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "protobuf-c";
    repo = "protobuf-c";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bpxk2o5rYLFkx532A3PYyhh2MwVH2Dqf3p/bnNpQV7s=";
  };

  outputs = [
    "out"
    "dev"
    "lib"
  ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    protobuf
    zlib
  ];

  postPatch = ''
        # Add compatibility shim for protobuf >= 35.x where label() was removed.
        # Insert before the final #endif (header guard) in compat.h.
        sed -i '$ s|#endif.*|#include <google/protobuf/descriptor.h>\
    namespace protobuf_c { namespace compat {\
    inline google::protobuf::FieldDescriptor::Label\
    GetFieldLabel(const google::protobuf::FieldDescriptor *field) {\
      if (field->is_repeated()) return google::protobuf::FieldDescriptor::LABEL_REPEATED;\
      if (field->is_required()) return google::protobuf::FieldDescriptor::LABEL_REQUIRED;\
      return google::protobuf::FieldDescriptor::LABEL_OPTIONAL;\
    }\
    }} // namespace protobuf_c::compat\
    #endif /* PROTOC_GEN_C_COMPAT_H */|' protoc-gen-c/compat.h

        # Replace descriptor_->label() calls with the compatibility shim
        for f in protoc-gen-c/*.cc; do
          sed -i 's/descriptor_->label()/protobuf_c::compat::GetFieldLabel(descriptor_)/g' "$f"
        done
  '';

  env.PROTOC = lib.getExe buildPackages.protobuf;

  meta = {
    homepage = "https://github.com/protobuf-c/protobuf-c/";
    description = "C bindings for Google's Protocol Buffers";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})

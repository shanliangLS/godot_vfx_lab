"""Remove invalid empty texture objects from upstream UV-only FBX copies, retaining mesh data."""
from pathlib import Path
import struct

def strip_empty_textures(path: Path) -> int:
    blob = path.read_bytes()
    if not blob.startswith(b"Kaydara FBX Binary"):
        raise ValueError("Expected binary FBX")
    version = struct.unpack_from("<I", blob, 23)[0]
    header_format = "<QQQ" if version >= 7500 else "<III"
    header_size = struct.calcsize(header_format) + 1
    null = bytes(header_size)

    def parse(position):
        end, count, length = struct.unpack_from(header_format, blob, position)
        if not end:
            return None, position + header_size
        name_length = blob[position + header_size - 1]
        start = position + header_size
        name = blob[start:start + name_length]
        start += name_length
        props = blob[start:start + length]
        children = []
        position = start + length
        has_null = False
        while position < end:
            child, position = parse(position)
            if child is None:
                has_null = True
                break
            children.append(child)
        return [name, count, props, children, has_null], end

    nodes = []
    position = 27
    while True:
        node, position = parse(position)
        if node is None:
            break
        nodes.append(node)
    footer = blob[position:]
    removed = set()
    objects = next(node for node in nodes if node[0] == b"Objects")
    for node in objects[3]:
        if node[0] not in (b"Texture", b"Video"):
            continue
        filenames = [child for child in node[3] if child[0] in (b"FileName", b"Filename", b"RelativeFilename")]
        directory_reference = any(child[0] == b"RelativeFilename" and child[2][5:].strip(b"\x00 ") in (b"", b".", b"./", b".\\") for child in filenames)
        if filenames and (directory_reference or all(child[2] == b"S\x00\x00\x00\x00" for child in filenames)):
            assert node[2][:1] == b"L"
            removed.add(struct.unpack_from("<q", node[2], 1)[0])
    if not removed:
        return 0
    objects[3] = [node for node in objects[3] if not (node[0] in (b"Texture", b"Video") and struct.unpack_from("<q", node[2], 1)[0] in removed)]
    connections = next(node for node in nodes if node[0] == b"Connections")
    def keep_connection(node):
        props = node[2]
        if node[0] != b"C" or props[:1] != b"S":
            return True
        offset = 5 + struct.unpack_from("<I", props, 1)[0]
        for _ in range(2):
            assert props[offset:offset + 1] == b"L"
            identity = struct.unpack_from("<q", props, offset + 1)[0]
            if identity in removed:
                return False
            offset += 9
        return True
    connections[3] = [node for node in connections[3] if keep_connection(node)]

    def encode(node, position):
        name, count, props, children, has_null = node
        body = name + props
        for child in children:
            body += encode(child, position + header_size + len(body))
        if has_null:
            body += null
        return struct.pack(header_format, position + header_size + len(body), count, len(props)) + bytes([len(name)]) + body
    result = blob[:27]
    for node in nodes:
        result += encode(node, len(result))
    result += null + footer
    path.write_bytes(result)
    return len(removed)

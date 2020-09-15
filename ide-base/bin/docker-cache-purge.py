#! /usr/bin/env python

"""
Command to find and purge all descendant images, and remove all finished
containers relying on those images.

Does NOT prune ancestors! This command should be used to debug a build phase,
essentially.
"""

import argparse
import docker

def find_img(img_idx, id):
    try:
        return img_idx[id]
    except KeyError:
        for k, v in img_idx.items():
            if k.rsplit(":", 1)[-1].startswith(id):
                return v
    raise RuntimeError("No image with ID: %s" % id)

def get_children(img_idx):
    rval = {}
    for img in img_idx.values():
        p_id = img.attrs["Parent"]
        rval.setdefault(p_id, set()).add(img.id)
    return rval

def find_descendants(img, img_idx, children_map):
    children_ids = children_map.get(img.id, [])
    for id in children_ids:
        child = img_idx[id]
        yield child

def main(args):
    client = docker.from_env()
    img_idx = {_.id: _ for _ in client.images.list(all=True)}
    children_map = get_children(img_idx)

    img = find_img(img_idx, args.id)

    all_desc = []  # Set of all descendant images -- order matters
    stack = [img]
    while stack:
        s = stack.pop()
        all_desc.append(s)
        stack.extend(find_descendants(s, img_idx, children_map))

    # Print images
    print('Images')
    for i in all_desc:
        print(f'{i.id} {i.tags}')

    # Find containers relying on any of these images
    print('Containers')
    autofail = False
    all_cont = []
    for c in client.containers.list(all=True):
        if c.image in all_desc:
            all_cont.append(c)
            print(f'{c} {c.status} {c.image.id} {c.image.tags}')

            if c.status != 'exited':
                autofail = True

    if autofail:
        print('Some containers relying on these image(s) running.')
        print('Please kill containers before proceeding.')
        return

    print('')
    c = input('Proceed to `docker rm` containers and `docker rmi` images? (y/N) ')
    if c != 'y':
        print('Aborted.')
        return

    for c in all_cont:
        c.remove()
    for i in reversed(all_desc):
        # Remove in opposite order, so we don't get error messages
        assert i.id.startswith('sha256:'), i.id
        client.images.remove(i.id[7:], noprune=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("id", metavar="IMAGE_ID")
    main(parser.parse_args())


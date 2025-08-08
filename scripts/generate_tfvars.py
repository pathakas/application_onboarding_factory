import os
import sys
import json
import re

def replace_placeholders(content, env):
    missing = []
    def repl(match):
        key = match.group(1)
        if key in env and env[key] != "":
            return env[key]
        else:
            missing.append(key)
            return match.group(0)  # keep placeholder for now
    result = re.sub(r"\$\{\{(\w+)\}\}", repl, content)
    if missing:
        raise ValueError(f"Missing environment variables for placeholders: {', '.join(sorted(set(missing)))}")
    return result


def main():
    if len(sys.argv) != 3:
        print("Usage: python generate_tfvars.py <base_tfvars_template> <file_prefix>")
        sys.exit(1)
    tpl_path = sys.argv[1]
    file_prefix = sys.argv[2]
    envs_json = os.environ.get("APP_ENVT")
    if not envs_json:
        print("ERROR: APP_ENVT environment variable not set")
        sys.exit(1)
    try:
        envs = json.loads(envs_json)
    except Exception as e:
        print(f"ERROR: Unable to parse APP_ENVT: {e}")
        sys.exit(1)
    with open(tpl_path) as f:
        template = f.read()
    for env_obj in envs:
        code = env_obj.get("code", "env").lower()
        out_dir = code
        os.makedirs(out_dir, exist_ok=True)
        out_file = os.path.join(out_dir, f"{file_prefix}-{code}.tfvars")
        ctx = dict(os.environ)
        ctx.update(env_obj)
        result = replace_placeholders(template, ctx)
        if re.search(r"\$\{\{(\w+)\}\}", result):
            print(f"ERROR: Unresolved placeholders in {out_file}")
            sys.exit(1)
        with open(out_file, "w") as out:
            out.write(result)
        print(f"Generated: {out_file}")

if __name__ == "__main__":
    main()

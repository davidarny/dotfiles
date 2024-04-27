# Run npm fzf
function fnpm {
    local packages
    packages=$(all-the-package-names | fzf -m) &&
    echo "$packages" &&
    npm i $(echo $packages)
}

# Run git branch fzf
function fbr {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | 
        fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Batch rename
function brn {
    for file in *$1*; do mv "$file" "${file/$1/$2}"; done
}

# Minify svg files in a folder
function svgmin {
    svgo --config /Users/david_arutiunian/svgo.config.js -f $1 -o $2
}

# Copy package version
function cpver {
    echo -n $(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[", ]//g') | pbcopy
}

# Scaffold react component strucutre
function crc {
    mkdir $1 && cd $1

    if [[ "$@" == *"-i"* ]]; then
        cat << EOF >> index.ts
export * from './${1}';
EOF
    fi

    if [[ "$@" == *"-s"* ]]; then
        cat << EOF >> $1.stories.tsx
import { ComponentMeta, ComponentStory } from '@storybook/react';

import { ${1} } from './${1}';

export default {
  component: ${1},
  title: 'components/${1}',
} as ComponentMeta<typeof ${1}>;

const Template: ComponentStory<typeof ${1}> = (args) => {
  return (
    <div className="story">
      <h2 className="story-title">Default</h2>
      <${1} {...args} />
    </div>
  );
};

export const Default = Template.bind({});
Default.args = {};
EOF
    fi

    cat << EOF >> $1.types.ts
export interface $1Props {
  className?: string;
}
EOF

    cat << EOF >> $1.module.scss
@import 'src/styles/services';
EOF

    cat << EOF >> $1.tsx
import { FC } from 'react';

import { ${1}Props } from './${1}.types';

import styles from './${1}.module.scss';

export const ${1}: FC<${1}Props> = ({ className }) => {
  return <div className={cn(styles.root, className)} />;
};
EOF

    cd ..
}

# Migrate npm global packages to new node version
function fnm_upgrade {
  fnm exec --using=$1 npm ls --global --json \
    | jq -r '.dependencies | to_entries[] | .key+"@"+.value.version' \
    | xargs npm i -g
}

# Upgrade @mwl/core-lib package
function mwl_core_upgrade() {
  local new_version="$1"
  sed -i '' "s|\"@mwl/core-lib\": \".*\",|\"@mwl/core-lib\": \"$new_version\",|" package.json
}

# Upgrade @mwl/ui package
function mwl_ui_upgrade() {
  local new_version="$1"
  sed -i '' "s|\"@mwl/ui\": \".*\",|\"@mwl/ui\": \"$new_version\",|" package.json
}

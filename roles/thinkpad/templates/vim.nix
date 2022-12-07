{ pkgs, ... }:
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    (neovim.override {
      vimAlias = true;
      withNodeJs = true;

      configure = {
        packages.myPlugins = with unstable.vimPlugins; {
          start = [
            vim-lastplace
            vim-nix
            fzf-vim
            nerdtree
            markdown-preview-nvim
            coc-nvim
            coc-tsserver
            coc-java
            coc-pyright
            coc-prettier
          ];
          opt = [];
        };
        customRC = ''
          " your custom vimrc
          set nocompatible
          set backspace=indent,eol,start
          set shiftwidth=2
          set tabstop=2
          set expandtab

          let mapleader = ","

          " Mappings for finding files with fzf
          nmap ; :Buffers<CR>
          nmap <Leader>t :Files<CR>
          nmap <Leader>r :Tags<CR>

          noremap <leader>nt :NERDTree<cr>
          noremap <leader>tsw :CocCommand tsserver.watchBuild<cr>
          noremap <leader>co :copen

          command! -nargs=0 Prettier :call CocAction('runCommand', 'prettier.formatFile')

          " Use tab for trigger completion with characters ahead and navigate.
          " NOTE: There's always complete item selected by default, you may want to enable
          " no select by `"suggest.noselect": true` in your configuration file.
          " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
          " other plugin before putting this into your config.
          inoremap <silent><expr> <TAB>
            \ coc#pum#visible() ? coc#pum#next(1) :
            \ CheckBackspace() ? "\<Tab>" :
            \ coc#refresh()
          inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

          function! CheckBackspace() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
          endfunction

          nmap <silent> [g <Plug>(coc-diagnostic-prev)
          nmap <silent> ]g <Plug>(coc-diagnostic-next)

          " GoTo code navigation.
          nmap <silent> gd <Plug>(coc-definition)
          nmap <silent> gy <Plug>(coc-type-definition)
          nmap <silent> gi <Plug>(coc-implementation)
          nmap <silent> gr <Plug>(coc-references)


          " Use K to show documentation in preview window.
          nnoremap <silent> K :call ShowDocumentation()<CR>

          function! ShowDocumentation()
            if CocAction('hasProvider', 'hover')
              call CocActionAsync('doHover')
            else
              call feedkeys('K', 'in')
            endif
          endfunction

          " Highlight the symbol and its references when holding the cursor.
          autocmd CursorHold * silent call CocActionAsync('highlight')

          " Symbol renaming.
          nmap <leader>rn <Plug>(coc-rename)

          " Formatting selected code.
          xmap <leader>f  <Plug>(coc-format-selected)
          nmap <leader>f  <Plug>(coc-format-selected)

          " Applying codeAction to the selected region.
          " Example: `<leader>aap` for current paragraph
          xmap <leader>a  <Plug>(coc-codeaction-selected)
          nmap <leader>a  <Plug>(coc-codeaction-selected)

          " Remap keys for applying codeAction to the current buffer.
          nmap <leader>ac  <Plug>(coc-codeaction)
          " Apply AutoFix to problem on the current line.
          nmap <leader>qf  <Plug>(coc-fix-current)


          let NERDTreeIgnore = ['\.pyc$', '\.so$', '\.swp$']

          " trim trailing whitespace
          autocmd BufWritePre * %s/\s\+$//e

        '';
      };
    }
  )];
}

import React from 'react'
import { render } from 'react-dom'
import ClassNames from 'classnames'
import HTML5Backend from 'react-dnd-html5-backend'
import { DragDropContext } from 'react-dnd'

import { RawFileBrowser, Headers, FileRenderers } from 'react-keyed-file-browser'


class StudentFileManger extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: []
    };
  }

  componentDidMount() {
    window.modal_addnew = new ModalMarkus('#addnew_dialog');
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.populate_student_file_manager_assignment_submissions_path(this.props.assignment_id), {
      credentials: 'same-origin',
      headers: {
        'content-type': 'application/json'
      }
    }).then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  handleDeleteFile = (fileKey) => {
    let deleteFiles = [];
    this.state.files.map((file) => {
      if (file.key === fileKey) {
        deleteFiles.push(file)
      }
    });
    if (!deleteFiles) {
      return;
    }

    let file = deleteFiles[0];
    let file_revisions = {};
    file_revisions[file.key] = file.last_modified_revision;
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: {
        delete_files: [file.key],
        file_revisions: file_revisions
      }
    }).then(this.fetchData)
      .then(this.endAction);
  };

  handleActionBarDeleteClick = (event) => {
    event.preventDefault();
    if (this.state.selection) {
      this.handleDeleteFile(this.state.selection);
    }
  };

  render() {
    return (
      <FileManager
        files={this.state.files}
        // Override TableHeader
        headerRenderer={FileManagerHeader}
        fileRenderer={FileManagerFile}

        onDeleteFile={this.handleDeleteFile}
      />
    );
  }
}


class RawFileManager extends RawFileBrowser {
  handleActionBarAddFileClick = (event) => {
    event.preventDefault();
    // TODO: remove the reference to a global variable here.
    window.modal_addnew.open();
  };

  renderActionBar(selectedItem) {
    const selectionIsFolder = (selectedItem && !selectedItem.size)
    let filter
    if (this.props.canFilter) {
      filter = (
        <this.props.filterRenderer
          value={this.state.nameFilter}
          updateFilter={this.updateFilter}
          {...this.props.filterRendererProps}
        />
      )
    }

    let actions
    if (selectedItem) {
      // Something is selected. Build custom actions depending on what it is.
      if (selectedItem.action) {
        // Selected item has an active action against it. Disable all other actions.
        let actionText
        switch (selectedItem.action) {
          case 'delete':
            actionText = 'Deleting ...'
            break

          case 'rename':
            actionText = 'Renaming ...'
            break

          default:
            actionText = 'Moving ...'
            break
        }
        actions = (
          // TODO: Enable plugging in custom spinner.
          <div className="item-actions">
            <i className="icon loading fa fa-circle-o-notch fa-spin"/> {actionText}
          </div>
        )
      }
      else {
        actions = []
        if (
          selectionIsFolder &&
          typeof this.props.onCreateFolder === 'function' &&
          !this.state.nameFilter
        ) {
          actions.push(
            <li key="action-add-folder">
              <a
                onClick={this.handleActionBarAddFolderClick}
                href="#"
                role="button"
              >
                <i className="fa fa-folder-o" aria-hidden="true"/>
                &nbsp;Add Subfolder
              </a>
            </li>
          )
        }
        if (
          selectedItem.keyDerived && (
                                    (selectionIsFolder && typeof this.props.onRenameFile === 'function') ||
                                    (!selectionIsFolder && typeof this.props.onRenameFolder === 'function')
                                  )
        ) {
          actions.push(
            <li key="action-rename">
              <a
                onClick={this.handleActionBarRenameClick}
                href="#"
                role="button"
              >
                <i className="fa fa-i-cursor" aria-hidden="true"/>
                &nbsp;Rename
              </a>
            </li>
          )
        }
        if (
          selectedItem.keyDerived && (
                                    (!selectionIsFolder && typeof this.props.onDeleteFile === 'function') ||
                                    (selectionIsFolder && typeof this.props.onDeleteFolder === 'function')
                                  )
        ) {
          actions.push(
            <li key="action-delete">
              <a
                onClick={this.handleActionBarDeleteClick}
                href="#"
                role="button"
              >
                <i className="fa fa-trash-o" aria-hidden="true"/>
                &nbsp;{I18n.t('delete')}
              </a>
            </li>
          )
        }
        // NEW
        actions.unshift(
          <li key="action-add-file>">
            <a
              onClick={this.handleActionBarAddFileClick}
              href="#"
              role="button"
            >
              <i className="fa fa-add-file-o" aria-hidden="true"/>
              &nbsp;{I18n.t('add_new')}
            </a>
          </li>
        );
        if (actions.length) {
          actions = (<ul className="item-actions">{actions}</ul>)
        }
        else {
          actions = (<div className="item-actions">&nbsp;</div>)
        }
      }
    }
    else {
      // Nothing selected: We're in the 'root' folder. Only allowed action is adding a folder.
      actions = []
      if (
        typeof this.props.onCreateFolder === 'function' &&
        !this.state.nameFilter
      ) {
        actions.push(
          <li key="action-add-folder">
            <a
              onClick={this.handleActionBarAddFolderClick}
              href="#"
              role="button"
            >
              <i className="fa fa-folder-o" aria-hidden="true"/>
              &nbsp;Add Folder
            </a>
          </li>
        )
      }
      // NEW
      actions.unshift(
        <li key="action-add-file>">
          <a
            onClick={this.handleActionBarAddFileClick}
            href="#"
            role="button"
          >
            <i className="fa fa-add-file-o" aria-hidden="true"/>
            &nbsp;{I18n.t('add_new')}
          </a>
        </li>
      );

      if (actions.length) {
        actions = (<ul className="item-actions">{actions}</ul>)
      }
      else {
        actions = (<div className="item-actions">&nbsp;</div>)
      }
    }

    return (
      <div className="action-bar">
        {filter}
        {actions}
      </div>
    );
  }
}

let FileManager = DragDropContext(HTML5Backend)(RawFileManager);


class FileManagerHeader extends Headers.TableHeader {
  render() {
    const header = (
      <tr
        className={ClassNames('folder', {
          dragover: this.props.isOver,
          selected: this.props.isSelected,
        })}
      >
        <th>{I18n.t('browse_submissions.filename')}</th>
        <th className="modified">{I18n.t('browse_submissions.last_revised')}</th>
        <th className="modified">{I18n.t('browse_submissions.revised_by')}</th>
      </tr>
    );

    if (
      typeof this.props.browserProps.createFiles === 'function' ||
      typeof this.props.browserProps.moveFile === 'function' ||
      typeof this.props.browserProps.moveFolder === 'function'
    ) {
      return this.props.connectDropTarget(header);
    } else {
      return header;
    }
  }
}

class FileManagerFile extends FileRenderers.RawTableFile {
  handleFileClick = (event) => {
    if (event) {
      event.preventDefault();
    }
  };

  render() {
    let icon
    if (this.isImage()) {
      icon = (<i className="fa fa-file-image-o" aria-hidden="true" />)
    } else if (this.isPdf()) {
      icon = (<i className="fa fa-file-pdf-o" aria-hidden="true" />)
    } else {
      icon = (<i className="fa fa-file-o" aria-hidden="true" />)
    }

    const inAction = (this.props.isDragging || this.props.action)

    let name
    if (!inAction && this.props.isDeleting) {
      name = (
        <form className="deleting" onSubmit={this.handleDeleteSubmit}>
          <a
            href={this.props.url || '#'}
            download="download"
            onClick={this.handleFileClick}
          >
            {icon}
            {this.getName()}
          </a>
          <span>
            <button type="submit">
              Confirm Deletion
            </button>
          </span>
        </form>
      )
    } else if (!inAction && this.props.isRenaming) {
      name = (
        <form className="renaming" onSubmit={this.handleRenameSubmit}>
          {icon}
          <input
            ref="newName"
            type="text"
            value={this.state.newName}
            onChange={this.handleNewNameChange}
            onBlur={this.handleCancelEdit}
            autoFocus
          />
        </form>
      )
    } else {
      name = (
        <a
          href={this.props.url || '#'}
          download={this.getName()}
        >
          {icon}
          {this.getName()}
        </a>
      )
    }

    let draggable = (
      <div>
        {name}
      </div>
    )
    if (typeof this.props.browserProps.moveFile === 'function') {
      draggable = this.props.connectDragPreview(draggable)
    }

    let row = (
      <tr
        className={ClassNames('file', {
          pending: (this.props.action),
          dragging: (this.props.isDragging),
          dragover: (this.props.isOver),
          selected: (this.props.isSelected),
        })}
        onClick={this.handleItemClick}
        onDoubleClick={this.handleItemDoubleClick}
      >
        <td className="name">
          <div style={{paddingLeft: (this.props.depth * 16) + 'px'}}>
            {draggable}
          </div>
        </td>
        <td className="modified">
          {typeof this.props.modified === 'undefined' ? '-' : this.props.modified}
        </td>
        <td className="modified">
          {this.props.revision_by}
        </td>
      </tr>
    );

    return this.connectDND(row)
  }
}

export function makeStudentFileManager(elem, props) {
  render(<StudentFileManger {...props} />, elem);
}
